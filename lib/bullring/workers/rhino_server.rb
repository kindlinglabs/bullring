require 'rhino'
require 'drb'
require 'logger'

module Bullring

  class DummyLogger
    def method_missing(m, *args, &block)  
      # ignore
    end
  end

  class RhinoServer
    
    @@dummy_logger = Bullring::DummyLogger.new
    
    def initialize
      @library_scripts = {}
      @setup_providers = []
      configure
      logger.info {"#{logname}: Started a RhinoServer instance at #{Time.now}"}
    end
    
    def configure(options={})
      @options ||= { :run_is_sealed => false,
                     :run_is_restrictable => true,
                     :run_timeout_secs => 0.5 }

      # Don't do a merge b/c jruby and ruby don't play nicely for some reason
      options.each{|k,v| @options[k] = v}
    end
    
    def load_setup(setup_provider)
      # Get the libraries from the setup provider and add them to our local list.
      # Hopefully, by calling 'to_s' we are getting copies that live only on our
      # side of DRb.  Store the provider so we can go back to it later if we 
      # find that we don't have a required library.  Use a list of providers b/c
      # some providers may have died off.
      
      setup_provider.libraries.each do |name, script|
        add_library(name.to_s, library.to_s)
      end
      
      @setup_providers.push(setup_provider)
    end
    
    def logger=(logger)
      @logger = logger
    end
    
    def logger
      @logger || @@dummy_logger
    end
        
    def add_library(name, script)
      @library_scripts[name] = script
    end
    
    def add_library_file(name, filename)
      raise NotYetImplemented
      script = read file into string
      @library_scripts[name] = script
    end
    
    def check(script, options)
      Rhino::Context.open do |context|
        context_wrapper {context.load(File.expand_path("../../js/jslint.min.js", __FILE__))}
        
        jslintCall = <<-RHINO_CALL
          JSLINT("#{prepare_source(script)}", {devel: false, 
                               bitwise: true, 
                               undef: true,
                               continue: true, 
                               unparam: true, 
                               debug: true, 
                               sloppy: true, 
                               eqeq: true, 
                               sub: true, 
                               es5: true, 
                               vars: true, 
                               evil: true, 
                               white: true, 
                               forin: true, 
                               passfail: false, 
                               newcap: true, 
                               nomen: true, 
                               plusplus: true, 
                               regexp: true, 
                               maxerr: 50, 
                               indent: 4});
        RHINO_CALL
        
        duration, result = context_wrapper {context.eval(jslintCall + "JSLINT.errors")}
        result
      end      
    end

    def run(script, options)
      Rhino::Context.open(:sealed => @options[:run_is_sealed], :restrictable => @options[:run_is_restrictable]) do |context|

        (options['library_names'] || []).each do |library_name|
          library_script = @library_scripts[library_name] || fetch_library_script!(library_name)
          context_wrapper {context.eval(library_script)}      
        end
          
        context.timeout_limit = @options[:run_timeout_secs]
        
        duration, result = context_wrapper {context.eval(script)}      
        result
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
      DRb.start_service "druby://localhost:#{myPort}", Bullring::RhinoServer.new
      DRb.thread.join
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

    ESCAPE_MAP = {
      '\\' => '\\\\', 
      "\r\n" => '\n', 
      "\n" => '\n', 
      "\r" => '\n', 
      '"' => '\"', 
      "'" => '\''
    }
          
    def prepare_source(source) 
     # escape javascript characters (similar to Rails escape_javascript)
     source.gsub!(/(\\|\r\n|[\n\r"'])/u) {|match| ESCAPE_MAP[match] }
     source   
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
    
    def logname; "Bullring Server"; end
    
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

