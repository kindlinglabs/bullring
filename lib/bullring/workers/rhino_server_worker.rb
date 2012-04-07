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
      @tunnel.kill if !@tunnel.nil?
      DRb.stop_service 
      @tunnel = nil
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

      
      
      if server_online?
        connect_to_server
      else
        Process.spawn(server_command, "#{Bullring.root}", "start", "#{Bullring.configuration.server_port}")#, "#{@port}")
        
        while (!server_online?)
          sleep(0.2)
        end
        
        connect_to_server
      end
   

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
      tunnel.run(script, options)
    end

    def isAlive?
      # TODO Look into Daemons::Monitor to make sure all is well. (or check all is well every few minutes?)
      # something like Daemons.group.first.running?
      !tunnel.nil? && tunnel.isAlive
    end
    
  private
    
    attr_accessor :tunnel 
    
    def server_online?
      Network::is_port_in_use?('localhost',2250)
    end
    
    def connect_to_server
      # puts "in connect_to_server"
      @tunnel = DRbObject.new nil, "druby://localhost:2250"
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