# require 'bullring/util/drubied_process'
require 'bullring/util/server_registry'
require 'bullring/util/server_proxy'

module Bullring

  class RhinoServerWorker < Bullring::Worker
        
    def initialize
      super
      
      init_options = {}
      init_options[:caller_name] = "Bullring"
      init_options[:process] = {
        :host => 'localhost',
        :port => Bullring.configuration.server_port,
        :command => File.join(Bullring.root, "/bullring/workers/rhino_server.sh"),
        :args => [Bullring.root, 
                  "start", 
                  "#{Bullring.configuration.server_port}",
                  Bullring.configuration.jvm_init_heap_size,
                  Bullring.configuration.jvm_max_heap_size,
                  Bullring.configuration.jvm_young_heap_size],
        :max_bringup_time => Bullring.configuration.server_max_bringup_time
      }
      
      # runtime_options = {
      #   :run_timeout_secs => Bullring.configuration.execution_timeout_secs
      # }
      
      @server = ServerProxy.new(init_options)
      @setup_provider = SetupProvider.new(self)
      
      # @server = DrubiedProcess.new(options) do |process|
      #   process.configure({:run_timeout_secs => Bullring.configuration.execution_timeout_secs})
      #   process.load_setup(SetupProvider.new(self))
      # end
    end    
    
    # All methods need to get a server first
    
    def _add_library(name, script)
      rescue_me do
        server.add_library(name, script)
      end
    end

    def _check(script, options)
      options[:setup_provider] ||= @setup_provider
      
      rescue_me do 
        server.check(script, options)
      end
    end

    def _run(script, options)
      options[:run_timeout_secs] ||= Bullring.configuration.execution_timeout_secs
      # options[:setup_provider] ||= @setup_provider
      
      rescue_me do
        debugger
        result = server.run(script, options)
        result.respond_to?(:to_h) ? result.to_h : result      
      end
    end

    def _alive?
      server.alive?
    end
    
    def _discard;  end
    
    # The SetupProvider gives a way for the server to pull all the libraries in case 
    # of restart
    
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
      @times_rescued = 0
      begin
        yield
      rescue DRb::DRbConnError => e
        Bullring.logger.error {"Bullring: Encountered a DRb connection error at time #{Time.now}: " + e.inspect}
        
        if (@times_rescued += 1) < 2
          Bullring.logger.debug {"Bullring: Attempting to restart the server at time #{Time.now}"}
          @server.restart_if_needed!
          retry
        else
          raise e
        end
      rescue Bullring::JSError => e
        Bullring.logger.debug {"Bullring: Encountered a JSError: " + e.inspect}
        raise e
      rescue DRb::DRbUnknownError => e
        Bullring.logger.error {"Bullring: Caught an unknown DRb error: " + e.inspect}
        raise e.unknown
      end  
    end
    
    attr_accessor :server 

  end
  
end

