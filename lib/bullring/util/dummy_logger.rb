
module Bullring
  
  class DummyLogger
    def method_missing(m, *args, &block)  
      # ignore
    end
  end
  
end