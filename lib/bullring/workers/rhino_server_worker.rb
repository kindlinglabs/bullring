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
      
      @libraries = []
      
      @server = DrubiedProcess.new(options) do |process|
        process.configure({:run_timeout_secs => Bullring.configuration.execution_timeout_secs, 
                           :logger => Bullring.logger})
        process.load_setup(SetupProvider.new(self))
      end
    end
    
    def add_library(script)
      # this guy needs to maintain the library scripts in case the server restarts, in which
      # case the server will request the libraries through the SetupProvider
      @libraries.push(script)
    end

    def add_library_file(filename)
      raise NotYetImplemented
      # server.add_library_script(filename)
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
    
    attr_accessor :server 

  end
  
end

