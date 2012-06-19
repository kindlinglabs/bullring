require 'rhino'
require 'drb'
require 'logger'

unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative 'common'
require_relative '../util/dummy_logger'
require_relative '../util/server_registry'

module Bullring

  class RhinoServer
        
    def initialize(host, registry_port)
      @library_cache = {}
      
      @default_options = { :run_is_sealed => false,
                           :run_is_restrictable => true,
                           :run_timeout_secs => 0.5 }

      # Connect to the server registry
      @server_registry = ServerRegistry.new(host,registry_port, nil)

      # Start up as a DRb server (get the port from the registry)
      port = @server_registry.next_server_port
      uri = "druby://#{host}:#{port}"
      DRb.start_service uri, self

      # Put ourselves on the registry
      @server_registry.register_server(uri)

      # Keep an eye on the registry, if it dies, we should die
      Thread.new do
        while (true) do
          sleep(5)
          begin 
            @server_registry.test!
          rescue
            DRb.stop_service
            Thread.main.exit
          end
        end
      end
      
      DRb.thread.join
    end
    
    def logger=(logger)
      @logger = logger
    end
    
    def logger
      @logger ||= Bullring::DummyLogger.new
    end
            
    def get_library(name)
      @library_cache[name] ||= fetch_library(name)
    end
    
    def check(script, options)
      Rhino::Context.open do |context|
        context_wrapper {context.load(File.expand_path("../../js/jslint.min.js", __FILE__))}
        
        call = Bullring::Helper::jslint_call(script)
        
        duration, result = context_wrapper {context.eval(call)}
        
        result = result.collect{|obj| obj.respond_to?(:to_h) ? obj.to_h : obj}
      end      
    end

    def run(script, options)
      # Don't do a merge b/c jruby and ruby don't play nicely for some reason
      @default_options.each{|k,v| options[k] = v}
      
      Rhino::Context.open(:sealed => options[:run_is_sealed], :restrictable => options[:run_is_restrictable]) do |context|

        (options['library_names'] || []).each do |library_name|
          library_script = get_library(library_name)
          context_wrapper {context.eval(library_script)}      
        end
          
        context.timeout_limit = options[:run_timeout_secs]
        
        duration, result = context_wrapper {context.eval(script)}      
        result.respond_to?(:to_h) ? result.to_h : result      
      end      
    end
    
    def alive?
      true
    end
    
    def kill
      DRb.stop_service
      exit
    end
    
    def self.start(host, registry_port)
      RhinoServer.new(host, registry_port)
    end
    
  protected

    def context_wrapper
      begin 
        start_time = Time.now
        result = yield
        duration = Time.now - start_time
        
        logger.debug {"#{logname}: Ran script (#{duration} secs); result: " + result.inspect}
        
        return duration, result
      rescue Rhino::JSError => e
        logger.debug {"#{logname}: JSError! #{e.inspect}"}
        
        error = Bullring::JSError.new(e.message.to_s)
        
        if e.message.respond_to?(:keys)
          e.message.each do |k,v|
            error[k.to_s] = v.to_s
          end
        end
        
        raise error
      rescue Rhino::RunawayScriptError, Rhino::ScriptTimeoutError => e
        logger.debug {"#{logname}: Runaway Script: " + e.inspect}
        raise Bullring::JSError, "Script took too long to run"
      rescue NameError => e
        logger.debug {"#{logname}: Name error: " + e.inspect}
      rescue StandardError => e
        logger.debug {"#{logname}: StandardError: " + e.inspect}
        raise
      end
    end
    
    # Grab the library from the registry server
    def fetch_library(name)
      library_script = @server_registry['library', name]
      
      logger.debug {"#{logname}: Tried to fetch script '#{name}' from the registry and it " +
                    "was #{'not ' if library_script.nil?}found."}

      raise NameError, "Server cannot find a script named #{name}" if library_script.nil?

      library_script
    end
    
    def logname; "Bullring (Rhino Server)"; end
    
  end
  
end

#
# Handle command line arguments
#

command = ARGV[0]
host = ARGV[1]
registry_port = ARGV[2]

case command
when "start"
  Bullring::RhinoServer.start(host, registry_port)
end

