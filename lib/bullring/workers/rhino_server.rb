require 'rhino'
require 'drb'
require 'logger'

module Bullring

  class RhinoServer
    
    def initialize
      @library_scripts = []
      configure
    end
    
    def configure(options={})
      @options ||= { :run_is_sealed => false,
                     :run_is_restrictable => true,
                     :run_timeout_secs => 0.5 }

      # Don't do a merge b/c jruby and ruby don't play nicely for some reason
      options.each{|k,v| @options[k] = v}
      
      @logger = options[:logger] || DummyLogger.new
    end
    
    def add_library(script)
      @library_scripts.push(script)
    end
    
    def add_library_file(filename)
      raise NotYetImplemented
      script = read file into string
      @library_scripts.push(script)
    end
    
    def check(script, options)
      Rhino::Context.open do |context|
        context.load(File.expand_path("../../js/jslint.min.js", __FILE__))

        jslintCall = <<-RHINO_CALL
          JSLINT('#{script}', {devel: false, 
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
        
        context.eval(jslintCall + "JSLINT.errors")      
      end      
    end

    def run(script, options)
      begin 
        Rhino::Context.open(:sealed => @options[:run_is_sealed], :restrictable => @options[:run_is_restrictable]) do |context|
          @library_scripts.each {|library| context.eval(library)}      
            
          context.timeout_limit = @options[:run_timeout_secs]
          
          start_time = Time.now
          result = context.eval(script)
          duration = Time.now - start_time
          
          @logger.debug("Ran script (#{duration} secs); result: " + result.inspect)
          
          result
        end
      rescue Rhino::JSError => e
        @logger.debug("JSError! Cause: " + e.cause + "; Message: " + e.message + "; script: " + script.inspect)
        jsError = JSError.new
        jsError.cause = e.cause.to_s
        jsError.message = e.message.to_s
        jsError.backtrace = []
        raise jsError
      rescue Rhino::RunawayScriptError => e
        @logger.debug("Runaway Script: " + e.inspect)
        jsError = JSError.new
        jsError.cause = "Script took too long to run"
        raise jsError
      rescue Exception => e
        @logger.debug("Exception: " + e.inspect)
        raise e
      rescue Error => e
        @logger.debug("Error: " + e.inspect)
        raise e
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
    
  end
  
  class JSError < StandardError
    attr_accessor :cause
    attr_accessor :backtrace
    attr_accessor :message
  end
  
  class DummyLogger
    def method_missing(m, *args, &block)  
      # ignore
    end
  end
  
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

