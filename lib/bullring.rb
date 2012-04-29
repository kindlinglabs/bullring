require 'bullring/version'
require 'bullring/worker'
require 'uglifier'

module Bullring
  
  class << self
        
    def logger=(logger)
      @logger = logger
    end
    
    def logger
      @logger ||= DummyLogger.new
    end
    
    # Order is important (and relative to calls to add_library)
    def add_library_file(name, filename)
      worker.add_library_file(name, filename)
    end
    
    # Order is important (and relative to calls to add_library_script)
    def add_library(name, script)
      script = Uglifier.compile(script, :copyright => false) if configuration.minify_libraries
      worker.add_library(name, script)
    end
    
    def check(script, options = {})
      worker.check(script, options)
    end
    
    def run(script, options = {})
      worker.run(script, options)
    end
    
    def alive?
      worker.alive?
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
      attr_accessor :execution_timeout_secs
      attr_accessor :server_port
      attr_accessor :jvm_init_heap_size
      attr_accessor :jvm_max_heap_size
      attr_accessor :jvm_young_heap_size
      attr_accessor :minify_libraries
      attr_accessor :server_max_bringup_time
      
      def initialize      
        @execution_timeout_secs = 0.5
        @server_port = 3030
        @jvm_init_heap_size = '128m'
        @jvm_max_heap_size = '128m'
        @jvm_young_heap_size = '64m'
        @minify_libraries = true
        @server_max_bringup_time = 20 #seconds
        super
      end
    end
    
  private
    
    attr_accessor :worker 
    
    def worker
      if @worker.nil?
        # TODO here, choose the appropriate worker (may be a non-server one for dev)
        @worker = RhinoServerWorker.new
      end
      
      @worker
    end
    
  end
  
  class DummyLogger
    def method_missing(m, *args, &block)  
      # ignore
    end
  end
  
end
