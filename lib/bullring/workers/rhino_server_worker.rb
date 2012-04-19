require 'bullring/util/drubied_process'

module Bullring

  class RhinoServerWorker < Bullring::Worker
    
    def discard
      # Daemons.run(server_command, stop_options) 
      # @server.kill if !@server.nil?
      # DRb.stop_service 
      # @server = nil
    end
    
    def initialize
      # TODO add development environment switch here so that developers
      # can just use therubyracer (or rhino or whatever) directly
      # If already using jruby, can also just use rhino directly

      options = {}
      options[:process] = {
        :host => 'localhost',
        :port => Bullring.configuration.server_port,
        :command => File.join(Bullring.root, "/bullring/workers/rhino_server.sh"),
        :args => [Bullring.root, 
                  "start", 
                  "#{Bullring.configuration.server_port}",
                  Bullring.configuration.jvm_init_heap_size,
                  Bullring.configuration.jvm_max_heap_size,
                  Bullring.configuration.jvm_young_heap_size]
      }
      
      @server = DrubiedProcess.new(options)

      @server.configure({:run_timeout_secs => Bullring.configuration.execution_timeout_secs, 
                         :logger => Bullring.logger})
    end
    
    # TODO important! this guy needs to know if the daemon crashed and restarted (so that it
    # can repopulate its library scripts; alternatively, we could pass the library scripts
    # in on the command line, in which case the restarting would pick them up)
    
    def add_library(script)
      # this guy needs to maintain the library scripts in case the daemon restarts
      server.add_library(script)
    end

    def add_library_file(filename)
      server.add_library_script(filename)
    end

    def check(script, options)
      server.check(script, options)
    end

    def run(script, options)
      begin
        result = server.run(script, options)
        result.respond_to?(:to_h) ? result.to_h : result
      rescue DRb::DRbUnknownError => e
        raise e.unknown
      rescue Bullring::JSError => e
        raise e
      end
    end

    def alive?
      server.alive?
    end
    
  private
    
    attr_accessor :server 

  end
  

  
end

