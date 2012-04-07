require 'bullring/util/exceptions'

# TODO this class may have the common uglifier code, maybe some common 
# caching code

module Bullring
  class Worker

    def addLibrary(script)
      raise AbstractMethodCalled
    end
    
    def addLibraryFile(filename)
      raise AbstractMethodCalled
    end
    
    def check(script, options)
      raise AbstractMethodCalled
    end

    def run(script, options)
      raise AbstractMethodCalled
    end
    
    def isAlive?
      raise AbstractMethodCalled
    end
    
    def discard
      raise AbstractMethodCalled
    end
    
  end
end

require 'bullring/workers/rhino_server_worker'