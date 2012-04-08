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
    def initialize(options)
      @options = options
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
      @process.method_missing(m, args, block)
    end

    def process_port_active?
      Network::is_port_in_use?(@options[:process][:host],@options[:process][:port])
    end

    # Creates a druby connection to the process, starting it up if necessary
    def connect_to_process!
      if !process_port_active?
        Process.spawn([@options[:process][:command], @options[:process][:args]].flatten.join(" "))

        while (!process_port_active?)
          sleep(0.2)
        end
      end

      @process = DRbObject.new nil, "druby://#{@options[:process][:host]}:#{@options[:process][:port]}"
    end
  end
  
end