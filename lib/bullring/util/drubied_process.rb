require 'drb'
require 'bullring/util/network'

# Acts like a druby connection to a separate process (which this class will
# run if it isn't already running or if it dies).  The separate process must
# start a druby server and expose an front object.
#
module Bullring
  class DrubiedProcess
  
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
      connect_to_process!
    end

    def alive?
      begin
        @process.nil? || @process.alive?
      rescue DRb::DRbConnError
        return false
      rescue # things like name errors, in case server doesn't have an alive? method
        true
      end
    end

    def restart_if_needed!
      alive? || connect_to_process!
    end

    def method_missing(m, *args, &block)  
      restart_if_needed!
      @process.send(m, *args, &block)
    end

    def process_port_active?
      in_use = Network::is_port_in_use?(@options[:process][:host],@options[:process][:port])
      Bullring.logger.debug {"#{caller_name}: Port #{port} on #{host} is #{in_use ? 'active' : 'inactive'}."}
      in_use
    end

    # Creates a druby connection to the process, starting it up if necessary
    def connect_to_process!
      Bullring.logger.debug{"#{caller_name}: Connecting to process..."}

      if !process_port_active?
        Bullring.logger.debug {"#{caller_name}: Spawning process..."}

        Process.spawn([@options[:process][:command], @options[:process][:args]].flatten.join(" "))

        while (!process_port_active?)
          sleep(0.2)
        end
      end

      local_service = DRb.start_service "druby://localhost:0"
      Bullring.logger.debug {"#{caller_name}: Started local service on #{local_service.uri}"}

      @process = DRbObject.new nil, "druby://#{@options[:process][:host]}:#{@options[:process][:port]}"
      
      @after_connect_block.call(@process) if !@after_connect_block.nil?
    end
    
    protected
    
    def caller_name; @options[:caller_name]; end
    def port; @options[:process][:port]; end
    def host; @options[:process][:host]; end
  end
  
end