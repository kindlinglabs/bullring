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
    
    # attr_reader :uri
    
    def initialize(uri)
      # @uri = uri
      @library_scripts = {}
      @setup_providers = []
      
      @default_options = { :run_is_sealed => false,
                           :run_is_restrictable => true,
                           :run_timeout_secs => 0.5 }
      
      # Connect to the server registry
      server_registry = ServerRegistry.new("127.0.0.1","2999")
      
      # Start up as a DRb server
      DRb.start_service uri, self
      
      puts "about to register server #{uri}"
      # Put ourselves on the registry
      server_registry.register_server(uri)
      puts 'finished register server'
      
      logger.info {"#{logname}: Started a RhinoServer instance at #{Time.now}"}
      
      DRb.thread.join
    end
    
    # def configure(options={})
    #   @options ||= { :run_is_sealed => false,
    #                  :run_is_restrictable => true,
    #                  :run_timeout_secs => 0.5 }
    # 
    #   # Don't do a merge b/c jruby and ruby don't play nicely for some reason
    #   options.each{|k,v| @options[k] = v}
    # end
    
    # def load_setup(setup_provider)
    #     # Get the libraries from the setup provider and add them to our local list.
    #     # Hopefully, by calling 'to_s' we are getting copies that live only on our
    #     # side of DRb.  Store the provider so we can go back to it later if we 
    #     # find that we don't have a required library.  Use a list of providers b/c
    #     # some providers may have died off.
    #     
    #     setup_provider.libraries.each do |name, script|
    #       add_library(name.to_s, library.to_s)
    #     end
    #     
    #     @setup_providers.push(setup_provider)
    #   end
    
    def logger=(logger)
      @logger = logger
    end
    
    def logger
      @logger ||= Bullring::DummyLogger.new
    end
        
    def add_library(name, script)
      @library_scripts[name] = script
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
          library_script = @library_scripts[library_name] || fetch_library_script!(library_name)
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
    
    def self.start(myPort, clientPort)
      RhinoServer.new("druby://127.0.0.1:#{myPort}")
      # DRb.start_service "druby://127.0.0.1:#{myPort}", Bullring::RhinoServer.new
      # DRb.thread.join
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
        logger.debug {"#{logname}: JSError! Cause: " + e.cause + "; Message: " + e.message}
        raise Bullring::JSError, e.message.to_s, caller
      rescue Rhino::RunawayScriptError, Rhino::ScriptTimeoutError => e
        logger.debug {"#{logname}: Runaway Script: " + e.inspect}
        raise Bullring::JSError, "Script took too long to run", caller
      rescue NameError => e
        logger.debug {"#{logname}: Name error: " + e.inspect}
      rescue StandardError => e
        logger.debug {"#{logname}: StandardError: " + e.inspect}
        raise
      end
    end
    
    # Goes back to the setup provider to the get the named script or throws an
    # exception if there is no such script to retrieve.
    def fetch_library_script!(name)
      logger.debug {"#{logname}: The script named #{name} was not available so trying to fetch from clients"}

      while (provider = @setup_providers.last)
        begin
          library_script = provider.libraries[name]
          break if !library_script.nil?
        rescue DRb::DRbConnError => e
          logger.debug {"#{logname}: Could not connect to setup provider (its process probably died): " + e.inspect}
        rescue StandardError => e
          logger.error {"#{logname}: Encountered an unknown error searching setup providers for a script named #{name}: " + e.inspect}
        ensure
          # Toss the last element so we can continue searching prior elements
          setup_providers.pop
        end
      end

      # If after looking through the providers we are still empty handed, raise an error
      raise NameError, "Client doesn't have script named #{name}", caller if library_script.nil?
      
      add_library(name, library_script)
    end
    
    def logname; "Bullring (Rhino Server)"; end
    
  end
  
  class JSError < StandardError; end
  
end

#
# Handle command line arguments
#

command = ARGV[0]
myPort = ARGV[1]
clientPort = ARGV[2]

case command
when "start"
  Bullring::RhinoServer.start(myPort, clientPort)
end

