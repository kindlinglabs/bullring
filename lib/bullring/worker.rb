require 'bullring/util/exceptions'

# TODO this class may have the common uglifier code, maybe some common 
# caching code

module Bullring
  class Worker

    def add_library(name, script)
      raise AbstractMethodCalled
    end
    
    def add_library_file(name, filename)
      raise AbstractMethodCalled
    end
    
    def check(script, options)
      raise AbstractMethodCalled
    end

    def run(script, options)
      raise AbstractMethodCalled
    end
    
    def alive?
      raise AbstractMethodCalled
    end
    
    def discard
      raise AbstractMethodCalled
    end
    
  end
end

require 'bullring/workers/rhino_server_worker'