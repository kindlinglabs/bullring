
module Bullring

  class RacerWorker < Bullring::Worker
    
    def initialize
      super
    end
    
    def check(script, options)    
      context = V8::Context.new

      context_wrapper {context.load(File.expand_path("../../js/jslint.min.js", __FILE__))}

      call = Bullring::Helper::jslint_call(script)      
      duration, result = context_wrapper {context.eval(call)}

      result = result.collect{|obj| obj.respond_to?(:to_h) ? obj.to_h : obj}
    end

    def run(script, options)
      context = V8::Context.new

      (options['library_names'] || []).each do |library_name|
        library = libraries[library_name]
        context_wrapper {context.eval(library)}      
      end
      
      duration, result = context_wrapper {context.eval(script)}      
      result = result.respond_to?(:to_h) ? result.to_h : result      
    end

    def alive?
      true
    end
    
    def _discard; end
    
  protected

    def context_wrapper
      begin 
        start_time = Time.now
        result = yield
        duration = Time.now - start_time

        Bullring.logger.debug {"#{logname}: Ran script (#{duration} secs); result: " + result.inspect}

        return duration, result
      rescue V8::JSError => e
        Bullring.logger.debug {"#{logname}: JSError! Cause: " + e.cause + "; Message: " + e.message}
        raise Bullring::JSError, e.message.to_s, caller
      # rescue Rhino::RunawayScriptError, Rhino::ScriptTimeoutError => e
      #   logger.debug {"#{logname}: Runaway Script: " + e.inspect}
      #   raise Bullring::JSError, "Script took too long to run", caller
      rescue NameError => e
        Bullring.logger.debug {"#{logname}: Name error: " + e.inspect}
      rescue StandardError => e
        Bullring.logger.debug {"#{logname}: StandardError: " + e.inspect}
        raise
      end
    end
    
    def logname; "Bullring (Racer)"; end

  end

  
  
end

