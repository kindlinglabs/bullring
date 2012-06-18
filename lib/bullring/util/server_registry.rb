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
  class ServerRegistry
   
    attr_reader :tuplespace
   
    def initialize(host, port)
      @registry_host = host
      @registry_port = port
      
      @servers = {}
      
      registry_uri = "druby://#{host}:#{port}"
      
      if registry_unavailable?
        pid = Kernel.fork do
          @tuplespace = Rinda::TupleSpaceProxy.new(Rinda::TupleSpace.new)
          @tuplespace.write([:global_lock])
          @tuplespace.write([:next_client_id, 0])
          @tuplespace.write([:server_generation, 0])
          @tuplespace.write([:registry_open, true])
          DRb.start_service registry_uri, @tuplespace
          DRb.thread.join
        end
        Process.detach(pid)
        @tuplespace.write([:registry_pid], pid)
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
      @tuplespace ||= DRbObject.new_with_uri(registry_uri)
    end
    
    def next_available_client_id
      _, id = @tuplespace.take([:next_client_id, nil])
      @tuplespace.write([:next_client_id, id+1])
      id
    end
       
    # TODO internalize client_ids to this class
        
    def lease_server(client_id)
      fail_unless_registry_open!
      
      _, generation, uri = @tuplespace.take(['available', nil, nil]) # TODO can still take expired servers?
      @tuplespace.write(['leased', client_id, generation, uri])
      @servers[uri] ||= DRbObject.new nil, uri
    end
    
    def release_server(client_id)
      fail_unless_registry_open!
      
      # In case the lease wasn't successful, don't hang on the release
      begin
        ignore, ignore, generation, uri = @tuplespace.take(['leased', client_id, nil, nil], 0) 
        
        # Only register the server if its generation hasn't expired, otherwise
        # kill and forget
        if generation >= current_server_generation
          register_server(uri) 
        else
          kill_server(uri)
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
    
    def discard
      # TODO
    end
    
    def current_server_generation
      @tuplespace.read([:server_generation, nil])[1]
    end
    
    def register_server(uri)
      fail_unless_registry_open!
      @tuplespace.write(['available', current_server_generation, uri])
    end
    
    def dump_tuplespace
      @tuplespace.read_all(['available', nil, nil]).inspect + \
      @tuplespace.read_all(['leased', nil, nil, nil]).inspect + \
      @tuplespace.read_all([nil, nil, nil]).inspect
    end
        
    def []=(dictionary, key, value)
      with_lock do
        @tuplespace.take([dictionary, key, nil], 0) rescue nil
        @tuplespace.write([dictionary, key, value])
      end
    end
    
    def [](dictionary, key)
      with_lock do
        _, _, value = @tuplespace.read([dictionary, key, nil], 0) rescue nil
        return value
      end
    end
    
    def servers_are_registered?
      !@tuplespace.read_all(['available', current_server_generation, nil]).empty? ||
      !@tuplespace.read_all(['leased', nil, current_server_generation, nil]).empty?
    end
    
  private
  
    def with_lock
      lock = @tuplespace.take([:global_lock])
      yield
    ensure
      @tuplespace.write(lock) if lock
    end
      
    def registry_unavailable?
      Network::is_port_open?(@registry_host, @registry_port)
    end
    
    def kill_server(uri)
      @servers[uri].kill
      @servers[uri] = nil
    end
    
    # private
    def kill_available_servers(generation)
      begin
        while (tuple = @tuplespace.take(['available', generation, nil], 0))
          kill_server(tuple[2])
        end
      rescue
      end
    end
    
  end
  
  def fail_unless_registry_open!
    raise ServerRegistryClosed if !@tuplespace.read([:registry_open, nil])[1]
  end
  
  class ServerRegistryClosed < StandardError; end
  
end
  
  