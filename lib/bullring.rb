require 'bullring/version'
require 'bullring/worker'

module Bullring
  
  class << self
    
    attr_accessor :worker 
    def worker
      if @worker.nil?
        # TODO here, choose the appropriate worker (may be a non-server one for dev)
        @worker = RhinoServerWorker.new
      end
      
      @worker
    end
    
    def addLibraryFile(filename)
      worker.addLibraryFile(filename)
    end
    
    def addLibrary(script)
      worker.addLibrary(script)
    end
    
    def check(script, options = {})
      worker.check(script, options)
    end
    
    def run(script, options = {})
      worker.run(script, options)
    end
    
    def isAlive?
      worker.isAlive?
    end
    
    # Really only useful in development
    def discard
      worker.discard
    end
    
    def root
      @root ||= File.expand_path("..", __FILE__)
    end
    
    ###########################################################################
    #
    # Configuration machinery.
    #
    # To configure Bullring, put the following code in your applications 
    # initialization logic (eg. in the config/initializers in a Rails app)
    #
    #   Bullring.configure do |config|
    #     config.execution_timeout = 500
    #     ...
    #   end
    #
    
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    class Configuration
      attr_accessor :execution_timeout
      attr_accessor :server_port
      attr_accessor :pid_dir
      
      def initialize      
        @execution_timeout = 500
        @server_port = 3030
        @pid_dir = '/var/tmp/bullring_pids' # TODO pick something better in general
        super
      end
    end
    
  end
  
end
