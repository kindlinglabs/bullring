
module Bullring
  
  class SecurityTransgression < StandardError; end
  class AbstractMethodCalled < StandardError; end
  class NotYetImplemented < StandardError; end
  class IllegalArgument < StandardError; end
  class IllegalState < StandardError; end
  class PidDirUnavailable < StandardError; end
  
end