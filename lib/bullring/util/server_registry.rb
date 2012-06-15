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
          DRb.start_service registry_uri, @tuplespace
          DRb.thread.join
        end
        Process.detach(pid)
        
        # if i_can_serve_the_registry
        #   @tuplespace = Rinda::TupleSpaceProxy.new(Rinda::TupleSpace.new)
        #   DRb.start_service uri, @tuplespace
        # else
        #   # Hang out til the registry becomes available
        #   sleep(0.2) while registry_unavailable?
        # end
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
        
    def lease_server(client_id)
      ignore, uri = @tuplespace.take(['available', nil])
      # puts "took available server"
      @tuplespace.write(['leased', client_id, uri])
      # puts "noted that server as leased to client #{client_id}"
      @servers[uri] ||= DRbObject.new nil, uri
      # puts "made a new DRb object (#{@servers[uri]})for that server and will return it next"
      # dump_tuplespace
      @servers[uri]
    end
    
    def release_server(client_id)
      ignore, ignore, uri = @tuplespace.take(['leased', client_id, nil])
      register_server(uri)
      dump_tuplespace
    end
    
    def register_server(uri)
      # puts "in register server #{uri}"
      @tuplespace.write(['available', uri])
    end
    
    def dump_tuplespace
      @tuplespace.read_all(['available', nil]).inspect + @tuplespace.read_all(['leased', nil, nil]).inspect
    end
    
    def store_unique_data(type, name, data)
      @tuplespace.take([type, name, nil], 0)
    end
    
    def []=(dictionary, key, value)
      lock = @tuplespace.take([:global_lock])
      @tuplespace.take([dictionary, key, nil], 0) rescue nil
      @tuplespace.write([dictionary, key, value])
    ensure
      @tuplespace.write(lock) if lock
    end
    
    def [](dictionary, key)
      lock = @tuplespace.take([:global_lock])
      _, _, value = @tuplespace.read([dictionary, key, nil], 0) rescue nil
      return value
    ensure
      @tuplespace.write(lock) if lock
    end
    
    def servers_are_registered?
      !@tuplespace.read_all(['available', nil]).empty? ||
      !@tuplespace.read_all(['leased', nil, nil]).empty?
    end
    
  private
  
    def registry_unavailable?
      Network::is_port_open?(@registry_host, @registry_port)
    end
  
  end
end
  
  