require 'drb'
require 'rinda/tuplespace'

unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative 'network'

module Bullring
  
  class TuplespaceWrapper
    def initialize(uri)
      @tuplespace = DRbObject.new_with_uri(uri)
    end
    
    def method_missing(m, *args, &block)  
      begin
        @tuplespace.send(m, *args, &block)
      rescue DRb::DRbConnError, Errno::ECONNREFUSED => e
        Bullring.logger.debug {"Lost connection to the server registry"}
        raise ServerRegistryOffline, "The connection to the server registry was lost"
      end
    end
  end
  
  class ServerWrapper
    
    attr_reader :server
    
    def initialize(uri)
      @uri = uri
      @server = DRbObject.new_with_uri(uri)
    end
    
    def method_missing(m, *args, &block)  
      begin
        @server.send(m, *args, &block)
      rescue DRb::DRbConnError, Errno::ECONNREFUSED => e
        Bullring.logger.debug {"Lost connection to the server at #{@uri}"}
        raise ServerOffline, "The connection to the server at #{@uri} was lost"
      end
    end
  end
  
  class ServerRegistry
   
    attr_reader :tuplespace
   
    MAX_SERVERS_PER_GENERATION = 1
   
    def initialize(host, port, first_server_port, &start_server_block)
      @registry_host = @server_host = host
      @registry_port = port
      @start_server_block = start_server_block
      
      @servers = {}
      
      registry_uri = "druby://#{host}:#{port}"
      
      if registry_unavailable?
        pid = Kernel.fork do
          @tuplespace = Rinda::TupleSpaceProxy.new(Rinda::TupleSpace.new)
          @tuplespace.write([:global_lock])
          @tuplespace.write([:next_client_id, 0])
          @tuplespace.write([:server_generation, 0])
          @tuplespace.write([:next_server_port, "#{first_server_port}"]) if !first_server_port.nil?
          DRb.start_service registry_uri, @tuplespace
          
          Thread.new do
            @client_id = 'registry'
            @tuplespace.notify("write", [:registry_closed]).pop
            kill_available_servers
            Thread.main.exit
          end
          
          DRb.thread.join
        end
        Process.detach(pid)
      end
      
      time_sleeping = 0
      while (registry_unavailable?)
        sleep(0.2)
        if (time_sleeping += 0.2) > 20 #@options[:process][:max_bringup_time]
          Bullring.logger.error {"#{caller_name}: Timed out waiting to bring up the registry server"}
          raise StandardError, "#{caller_name}: Timed out waiting to bring up the registry server", caller
        end
      end
      
      # The registry should be available here so connect to it if we don't
      # already serve it.
      @tuplespace ||= TuplespaceWrapper.new(registry_uri)
      
      # Every user (client) of server registry has its own instance of the registry, so that
      # instance can store its own client id.
      _, @client_id = @tuplespace.take([:next_client_id, nil])
      @tuplespace.write([:next_client_id, @client_id + 1])
    end
    
    def next_server_port
      _, port = @tuplespace.take([:next_server_port, nil])
      port = port.to_i + 1 while !Network::is_port_open?(@server_host, port)
      @tuplespace.write([:next_server_port, "#{port.to_i + 1}"])
      port
    end
       
    # First starts up a server if needed then blocks until it is available and returns it
    def lease_server!
      begin
        if num_current_generation_servers < MAX_SERVERS_PER_GENERATION && registry_open?
          start_a_server 
        end

        lease_server
      rescue ServerOffline => e
        Bullring.logger.debug {"Lost connection with a server, retrying..."}
        retry
      end
    end
    
    # Blocks until a server is available, then returns it
    def lease_server
      server = _lease_server(:timeout => 0) until !server.nil?
      server
    end
    
    def release_server      
      # In case the lease wasn't successful, don't hang on the release
      begin
        _, _, generation, uri = @tuplespace.take(['leased', @client_id, nil, nil], 0) 
        
        # Only register the server if its generation hasn't expired, otherwise
        # kill and forget
        if generation < current_server_generation || !registry_open?
          @servers[uri].kill rescue ServerOffline
          @servers[uri] = nil
        else
          register_server(uri) 
        end        
      rescue Rinda::RequestExpiredError => e; end
    end
    
    def expire_servers
      with_lock do
        _, generation = @tuplespace.take([:server_generation, nil])
        @tuplespace.write([:server_generation, generation + 1])
        kill_available_servers(generation)
      end
    end    
    
    def close!
      @tuplespace.write([:registry_closed])
    end
    
    def register_server(uri)
      fail_unless_registry_open!
      @tuplespace.write(['available', current_server_generation, uri])
    end
        
    def []=(dictionary, key, value)
      with_lock do
        @tuplespace.take(['data', dictionary, key, nil], 0) rescue nil
        @tuplespace.write(['data', dictionary, key, value])
      end
    end
    
    def [](dictionary, key)
      with_lock do
        _, _, _, value = @tuplespace.read(['data', dictionary, key, nil], 0) rescue nil
        return value
      end
    end
    
    def current_server_generation
      @tuplespace.read([:server_generation, nil])[1]
    end
        
    def num_servers(generation = nil)
      @tuplespace.read_all(['available', generation, nil]).count + \
      @tuplespace.read_all(['leased', nil, generation, nil]).count      
    end
    
    def num_current_generation_servers
      num_servers(current_server_generation)
    end
    
    def registry_open?
      !tuple_present?([:registry_closed])
    end
    
    def test!
      @tuplespace.write([:temp])
    end
    
    def registry_unavailable?
      Network::is_port_open?(@registry_host, @registry_port)
    end
    
    def dump_tuplespace
      "Available: " + @tuplespace.read_all(['available', nil, nil]).inspect + \
      ", Leased: " + @tuplespace.read_all(['leased', nil, nil, nil]).inspect + \
      ", Data: " + @tuplespace.read_all(['data', nil, nil, nil]).inspect
    end
    
  private
  
    # If a server is unavailable after the timeout, either returns nil or throws 
    # an exception if the registry is closed at that time.
    #    options[:timeout] => a number of seconds or nil for no timeout (only use 0 or nil)
    #    options[:generation] => a generation number or nil for no generation requirement
    #    options[:ignore_closed_registry] => if true, don't throw exception if registry closed
    def _lease_server(options)
      options[:ignore_closed_registry] ||= false
      
      begin 
        # Get the server from the TS
        _, generation, uri = @tuplespace.take(['available', options[:generation], nil], options[:timeout])
        # Get the DRb object for it
        @servers[uri] ||= ServerWrapper.new(uri)
        # Check that the server is still up; the following call will throw if it is down
        @servers[uri].alive?
        # Note that we've leased this server
        @tuplespace.write(['leased', @client_id, generation, uri])
        # Return it
        @servers[uri] #.server    
      rescue ServerOffline => e
        @servers[uri] = nil
        raise   
      rescue Rinda::RequestExpiredError => e
        fail_unless_registry_open! if !options[:ignore_closed_registry]
      end
    end
  
    def tuple_present?(tuple)
      begin
        @tuplespace.read(tuple, 0)
        true
      rescue
        false
      end
    end
  
    def with_lock
      lock = @tuplespace.take([:global_lock])
      yield
    ensure
      @tuplespace.write(lock) if lock
    end
      
    def kill_available_servers(generation = nil)
      # Leasing and releasing will guarantee that we have a DRbObject for the server
      # and release_server already has the code for killing a server
      while num_servers(generation) != 0
        _lease_server({:timeout => 0, :ignore_closed_registry => true, :generation => generation}) 
        release_server
      end
    end
  
    def start_a_server
      raise IllegalState "The command to start a server is unavailable." if @start_server_block.nil?
      
      @start_server_block.call
    end
  
    def fail_unless_registry_open!
      raise ServerRegistryClosed if !registry_open?
    end
  
  end
  
  class ServerRegistryClosed < StandardError; end
  class ServerRegistryOffline < StandardError; end
  class ServerOffline < StandardError; end
  
end
  
  