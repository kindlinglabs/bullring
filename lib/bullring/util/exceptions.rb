
module Bullring
  
  class SecurityTransgression < StandardError; end
  class AbstractMethodCalled < StandardError; end
  class NotYetImplemented < StandardError; end
  class IllegalArgument < StandardError; end
  class IllegalState < StandardError; end
  class PidDirUnavailable < StandardError; end
  
  class JSError < StandardError
    attr_accessor :cause
    attr_accessor :backtrace
    attr_accessor :message
  end
  
end