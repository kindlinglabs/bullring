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

      # context.timeout = Bullring.configuration.execution_timeout_secs * 1000
      
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
        value = cleanup_exception_value(e.value)
        Bullring.logger.debug {"#{logname}: JSError! [#{value.to_s}]"}
        raise Bullring::JSError, value, caller
      rescue NameError => e
        Bullring.logger.debug {"#{logname}: Name error: " + e.inspect}
      rescue StandardError => e
        Bullring.logger.debug {"#{logname}: StandardError: " + e.inspect}
        raise
      end
    end

    def cleanup_exception_value(value)
      case value
      when String, Hash
        value
      when V8::Object
        hash = {}
        value.each{|k,v| hash[k] = cleanup_exception_value(v)}
        hash
      else
        value.to_s
      end
    end
    
    def logname; "Bullring (Racer)"; end

  end

  
  
end

