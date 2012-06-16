require 'bullring/util/server_registry'
require 'bullring/util/server_proxy'

module Bullring

  class RhinoServerWorker < Bullring::Worker
        
    def initialize
      super
      
      init_options = {}
      init_options[:caller_name] = "Bullring"
      init_options[:server] = {
        :command => File.join(Bullring.root, "/bullring/workers/rhino_server.sh"),
        :args => [Bullring.root, 
                  "start", 
                  "#{Bullring.configuration.server_port}",
                  Bullring.configuration.jvm_init_heap_size,
                  Bullring.configuration.jvm_max_heap_size,
                  Bullring.configuration.jvm_young_heap_size],
        :max_bringup_time => Bullring.configuration.server_max_bringup_time
      }
      init_options[:registry] = {
        :host => "127.0.0.1",
        :port => "2999"
      }
      init_options[:proxy] = {
        :host => "127.0.0.1"
      }
      
      @server = ServerProxy.new(init_options)
    end    
    
    def _add_library(name, script)
      rescue_me do
        server.store_in_registry('library', name, script)
      end
    end

    def _check(script, options)
      rescue_me do 
        server.check(script, options)
      end
    end

    def _run(script, options)
      options[:run_timeout_secs] ||= Bullring.configuration.execution_timeout_secs
      
      rescue_me do
        result = server.run(script, options)
        result.respond_to?(:to_h) ? result.to_h : result      
      end
    end

    def _alive?
      server.alive?
    end
    
    def _discard;  end
    
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

