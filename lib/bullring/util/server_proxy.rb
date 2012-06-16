require 'drb'
require 'bullring/util/network'
require 'bullring/util/server_registry'

# Acts like a druby connection to a separate process (which this class will
# run if it isn't already running or if it dies).  The separate process must
# start a druby server and expose an front object.
#
module Bullring
  class ServerProxy
  
    # options looks like:
    #
    # {
    #   :process => {
    #     :host => [the hostname / IP address that the process listens on],
    #     :port => [the port that the process listens on],
    #     :command => [the command to run the process],
    #     :args => [the arguments to the process command]
    #   }
    # }
    #
    # The provided block will be called whenever this process connects (or 
    # reconnects) to a process, including when the process is restarted. This
    # makes the block a good place to put initialization code for the process.
    #
    def initialize(options, &block)
      @options = options
      @after_connect_block = block
      # connect_to_process!
      @local_service = DRb.start_service "druby://127.0.0.1:0"
      @server_registry = ServerRegistry.new("127.0.0.1","2999")
    end
    
    def store_in_registry(dictionary, key, value)
      @server_registry[dictionary, key] = value
    end

    def alive?
      @server_registry.servers_are_registered?
      # begin
      #   (@process.nil? || @process.alive?).tap{|is_alive| Bullring.logger.debug {"#{caller_name} #{is_alive ? 'is alive!' : 'is not alive!'}"}}
      # rescue DRb::DRbConnError => e
      #   Bullring.logger.debug {"#{caller_name}: Checking if server alive and got a connection error: " + e.inspect}
      #   return false
      # rescue StandardError => e # things like name errors, in case server doesn't have an alive? method
      #   Bullring.logger.debug {"#{caller_name}: Checking if server alive and got an error: " + e.inspect}
      #   true
      # rescue
      #   Bullring.logger.debug {"#{caller_name}: Checking if server alive and got an unknown error"}
      #   true
      # end
    end

    def restart_if_needed!
      Bullring.logger.debug {"#{caller_name}: In restart_if_needed!"}
      # alive? || connect_to_process!
      spawn_server if !@server_registry.servers_are_registered?
    end

    def method_missing(m, *args, &block)  
      restart_if_needed!

      result = nil
      
      begin
        # puts "about to lease server to run method #{m}"
        server = @server_registry.lease_server(0) # TODO fix me
        # puts "leased server #{server}"

        server.logger = Bullring.logger
        # puts "set logger on server #{server}"
        result = server.send(m, *args, &block)
        # puts "ran method #{m} on server #{server}"
        server.logger = nil
        # puts "cleared logger on server #{server}"
      ensure
        @server_registry.release_server(0)
        puts "released server #{server} from client 0"
      end
      
      result
    end
    
    def spawn_server
      # Spawn the process in its own process group so it stays alive even if this process dies
      pid = Process.spawn([@options[:process][:command], @options[:process][:args]].flatten.join(" "), {:pgroup => true})
      Process.detach(pid)
    end

    # def process_port_active?
    #   in_use = Network::is_port_in_use?(host,port)
    #   Bullring.logger.debug {"#{caller_name}: Port #{port} on #{host} is #{in_use ? 'active' : 'inactive'}."}
    #   in_use
    # end

    # # Creates a druby connection to the process, starting it up if necessary
    # def connect_to_process!
    #   Bullring.logger.debug{"#{caller_name}: Connecting to process..."}
    # 
    #   if !process_port_active?
    #     Bullring.logger.debug {"#{caller_name}: Spawning process..."}
    # 
    #     # Spawn the process in its own process group so it stays alive even if this process dies
    #     pid = Process.spawn([@options[:process][:command], @options[:process][:args]].flatten.join(" "), {:pgroup => true})
    #     Process.detach(pid)
    # 
    #     time_sleeping = 0
    #     while (!process_port_active?)
    #       sleep(0.2)
    #       if (time_sleeping += 0.2) > @options[:process][:max_bringup_time]
    #         Bullring.logger.error {"#{caller_name}: Timed out waiting to bring up the process"}
    #         raise StandardError, "#{caller_name}: Timed out waiting to bring up the process", caller
    #       end
    #     end
    #   end
    # 
    #   if !@local_service.nil?
    #     @local_service.stop_service
    #     Bullring.logger.debug {"#{caller_name}: Stopped local service on #{@local_service.uri}"}
    #   end
    #   
    #   @local_service = DRb.start_service "druby://127.0.0.1:0"
    #   Bullring.logger.debug {"#{caller_name}: Started local service on #{@local_service.uri}"}
    # 
    #   @process = DRbObject.new nil, "druby://#{host}:#{port}"
    #   
    #   @after_connect_block.call(@process) if !@after_connect_block.nil?
    # end
    
    protected
    
    def caller_name; @options[:caller_name]; end
    def port; @options[:process][:port]; end
    def host; @options[:process][:host]; end
  end
  
end