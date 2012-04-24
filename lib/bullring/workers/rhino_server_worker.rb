require 'bullring/util/drubied_process'

module Bullring

  class RhinoServerWorker < Bullring::Worker
    
    attr_reader :libraries
    
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
            
      @libraries = {}
      
      @server = DrubiedProcess.new(options) do |process|
        process.configure({:run_timeout_secs => Bullring.configuration.execution_timeout_secs, 
                           :logger => Bullring.logger})
        process.load_setup(SetupProvider.new(self))
      end
    end    
    
    def add_library(name, script)
      # this guy needs to maintain the library scripts in case the server restarts, in which
      # case the server will request the libraries through the SetupProvider
      rescue_me do
        @libraries[name] = script
        server.add_library(name, script)
      end
    end

    def add_library_file(name, filename)
      raise NotYetImplemented
      # server.add_library_script(filename)
    end

    def check(script, options)
      rescue_me do 
        server.check(script, options)
      end
    end

    def run(script, options)
      rescue_me do
        result = server.run(script, options)
        result.respond_to?(:to_h) ? result.to_h : result      
      end
    end

    def alive?
      server.alive?
    end
    
    class SetupProvider
      include DRbUndumped

      def initialize(wrapped_provider)
        @wrapped_provider = wrapped_provider
      end

      def libraries
        @wrapped_provider.libraries
      end
    end
    
  private
  
    def rescue_me
      begin
        yield
      rescue DRb::DRbConnError => e
        Bullring.logger.error("Rescued a DRb connection error: " + e.inspect)
        @server.restart_if_needed!
        yield
      rescue DRb::DRbUnknownError => e
        raise e
      end  
    end
    
    attr_accessor :server 

  end
  
end

