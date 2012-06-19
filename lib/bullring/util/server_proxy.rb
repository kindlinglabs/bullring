require 'drb'
require 'bullring/util/network'
require 'bullring/util/server_registry'

# Interacts with the server registry to act like a server to its user.
#
module Bullring
  class ServerProxy
  
    # options looks like:
    #
    # {
    #   :server => {
    #     :command => [the command to run the process],
    #     :args => [the arguments to the process command]
    #   }
    #   :registry => {
    #     :host => [the host of the registry]
    #     :port => [the port the registry listens on]
    #   }
    #   :proxy => {
    #     :host => [the host that this proxy runs on (and listens on)]
    #   }
    # }
    #
    def initialize(options)
      @options = options
    end
    
    def store_in_registry(dictionary, key, value)
      server_registry[dictionary, key] = value
    end

    def method_missing(m, *args, &block)  
      result = nil
      num_retries = 0

      server = nil
      begin
        server = server_registry.lease_server!

        server.logger = Bullring.logger
        result = server.send(m, *args, &block)
        server.logger = nil
      rescue ServerRegistryOffline => e
        Bullring.logger.debug {"Lost connection to the server registry (proxy)"}
        connect!
        num_retries = num_retries + 1
        if (num_retries < 3)
          retry
        else
          raise 
        end
      ensure
        server_registry.release_server if !server.nil?
      end

      result
    end
    
    def discard
      server_registry.close!      
      sleep(0.5) while !server_registry.registry_unavailable?
      DRb.stop_service
      @server_registry = nil
    end
    
    def refresh
      server_registry.expire_servers
    end
    
    def server_registry
      connect! if @server_registry.nil?
      @server_registry
    end
    
  private
  
    def connect!
      DRb.stop_service
      @local_service = DRb.start_service "druby://#{@options[:proxy][:host]}:0"
      @server_registry = ServerRegistry.new(@options[:registry][:host],@options[:registry][:port]) do
        # Block to start a new server (spawn in its own process group so it 
        # stays alive even if the originating process dies)
        pid = Process.spawn([@options[:server][:command], 
                             @options[:server][:args]].flatten.join(" "), 
                             {:pgroup => true})
        Process.detach(pid)

      end
    end
    
  end
  
end