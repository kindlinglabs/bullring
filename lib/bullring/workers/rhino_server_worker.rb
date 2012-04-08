require 'daemons'
require 'drb'
require 'bullring/util/network'

module Bullring

  class RhinoServerWorker < Bullring::Worker
    
    # class Callback
    #   def initialize(daemonBackend)
    #     @daemonBackend = daemonBackend
    #   end
    #   def server_has_started
    #     puts "in callback"
    #     @daemonBackend.connect_to_server
    #   end
    # end
    
    def discard
      # Daemons.run(server_command, stop_options) 
      @server.kill if !@server.nil?
      DRb.stop_service 
      @server = nil
    end
    
    def initialize
      # TODO add development environment switch here so that developers
      # can just use therubyracer (or rhino or whatever) directly
      # If already using jruby, can also just use rhino directly

            # Dir.mkdir(Bullring.configuration.pid_dir) if !File::directory?(Bullring.configuration.pid_dir)
            #     
            # raise PidDirUnavailable if !File::writable?(Bullring.configuration.pid_dir)

      # DRb.start_service "druby://localhost:0", Callback.new(self)

      
      # DRb.uri =~ /^druby:\/\/(.*?):(\d+)(\?(.*))?$/
      # @port = $2.to_i
      # puts @port
      debugger

      connect_to_server!
         #    
         # if server_online?
         #   connect_to_server
         # else
         #   Process.spawn(server_command, "#{Bullring.root}", "start", "#{Bullring.configuration.server_port}")#, "#{@port}")
         #   
         #   while (!server_online?)
         #     sleep(0.2)
         #   end
         #   
         #   connect_to_server
         # end
   

            # Daemons.run(server_command, start_options)  

   
    end
    
    # TODO important! this guy needs to know if the daemon crashed and restarted (so that it
    # can repopulate its library scripts; alternatively, we could pass the library scripts
    # in on the command line, in which case the restarting would pick them up)
    
    def addLibrary(script)
      # this guy needs to maintain the library scripts in case the daemon restarts
      raise NotYetImplemented
    end

    def addLibraryFile(filename)
      raise NotYetImplemented
    end

    def check(script, options)
      raise NotYetImplemented
    end

    def run(script, options)
      isAlive? || connect_to_server!
      server.run(script, options)
    end

    def isAlive?
      begin
        !server.nil? && server.isAlive
      rescue DRb::DRbConnError
        return false
      end
    end
    
  private
    
    attr_accessor :server 
    
    def server_port_active?
      Network::is_port_in_use?('localhost',2250)
    end
    
    # If the server is online, this is the same as connect_to_server; otherwise,
    # this starts the server and then connects to it.
    def connect_to_server!
      if server_port_active?
        connect_to_server
      else
        Process.spawn(server_command, "#{Bullring.root}", "start", "#{Bullring.configuration.server_port}")#, "#{@port}")
        
        while (!server_port_active?)
          sleep(0.2)
        end
        
        connect_to_server
      end
    end
    
    # Sets up the DRb connection to the server (which is expected to be running)
    def connect_to_server
      @server = DRbObject.new nil, "druby://localhost:2250"
    end
    
    class ServerWrapper < DRbObject

      def initialize
        super(nil, "druby://localhost:2250")
      end

      def alive?
        begin
          super.isAlive
        rescue DRb::DRbConnError
          return false
        end
      end

      def method_missing(m, *args, &block)  
        isAlive? || connect_to_server!
        super(m, args, block)
      end
      
    end
    
    # def options
    #   { 
    #     :app_name   => app_name,
    #     :dir_mode   => :normal,
    #     :dir        => Bullring.configuration.pid_dir,
    #     :multiple   => false,
    #     :ontop      => false,
    #     :mode       => :exec,
    #     :backtrace  => true,
    #     :monitor    => true
    #   }
    # end
    # 
    # def app_name
    #   "bullring_backend"
    # end
    # 
    # def start_options
    #   options.merge({:ARGV => ['start', '-f', '--', "#{Bullring.root}", "start", "#{Bullring.configuration.server_port}"]})
    # end
    # 
    # def stop_options
    #   options.merge({:ARGV => ['stop', '-f']})
    # end    
    # 
    def server_command
      File.join(Bullring.root, "/bullring/workers/rhino_server.sh")
    end
    
  end

end