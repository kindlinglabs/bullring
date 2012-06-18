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
      @local_service = DRb.start_service "druby://#{options[:proxy][:host]}:0"
      @server_registry = ServerRegistry.new(options[:registry][:host],options[:registry][:port]) do
        # Block to start a new server (spawn in its own process group so it 
        # stays alive even if the originating process dies)
        pid = Process.spawn([@options[:server][:command], 
                             @options[:server][:args]].flatten.join(" "), 
                             {:pgroup => true})
        Process.detach(pid)
        
      end
    end
    
    def store_in_registry(dictionary, key, value)
      @server_registry[dictionary, key] = value
    end

    # def alive?
    #   @server_registry.servers_are_registered?
    # end

    # def restart_if_needed!
    #   spawn_server if !@server_registry.servers_are_registered?
    # end

    def method_missing(m, *args, &block)  
      # restart_if_needed!  # TODO put this into lease_server (means putting spawn_server into registry)
      debugger
      result = nil
      
      begin
        server = @server_registry.lease_server!

        server.logger = Bullring.logger
        result = server.send(m, *args, &block)
        server.logger = nil
      ensure
        @server_registry.release_server
      end
      
      result
    end
    
    def discard
      @server_registry.close!
    end
    
    def refresh
      @server_registry.expire_servers
    end
    
    # def spawn_server
    #   # Spawn the process in its own process group so it stays alive even if this process dies
    #   pid = Process.spawn([@options[:server][:command], 
    #                        @options[:server][:args]].flatten.join(" "), 
    #                        {:pgroup => true})
    #   Process.detach(pid)
    # end
    
  end
  
end