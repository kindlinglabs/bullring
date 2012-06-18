require 'bullring/util/exceptions'

module Bullring
  class Worker

    attr_reader :libraries
    
    def initialize
      @libraries = {}
    end

    def add_library(name, script)
      Bullring.logger.debug { "Bullring: Adding library named '#{name}'" }
      @libraries[name] = script
      _add_library(name, script)
    end
    
    def check(script, options)
      Bullring.logger.debug { "Bullring: Checking script with hash '#{script.hash}'" }
      _check(script, options)
    end

    def run(script, options)
      Bullring.logger.debug { "Bullring: Running script with hash '#{script.hash}'" }
      _run(script, options)
    end
    
    def alive?
      _alive?
    end
    
    def discard
      Bullring.logger.debug { "Bullring: Attempting to discard." }
      _discard
    end
    
    def refresh
      Bullring.logger.debug { "Bullring: Attempting to refresh." }
      _refresh
    end
    
  protected
    
    # Quasi-template method pattern
    def _add_library(name, script); end
    def _check(script, options); raise AbstractMethodCalled; end
    def _run(script, options); raise AbstractMethodCalled; end
    def _alive?; raise AbstractMethodCalled; end
    def _discard; raise AbstractMethodCalled; end
    
  end
end

require 'bullring/workers/rhino_server_worker'
require 'bullring/workers/racer_worker'

