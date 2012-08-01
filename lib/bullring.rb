require 'bullring/version'
require 'bullring/worker'
require 'bullring/util/dummy_logger'
require 'bullring/workers/common'
require 'uglifier'

module Bullring
  
  class << self
        
    def logger=(logger)
      @logger = logger
    end
    
    def logger
      @logger ||= DummyLogger.new
    end
    
    # Order is important (and relative to calls to add_library_script)
    def add_library(name, script)
      return if configuration.disabled
      script = Uglifier.compile(script, :copyright => false) if configuration.minify_libraries
      worker.add_library(name, script)
    end
    
    def check(script, options = {})
      return [] if configuration.disabled
      worker.check(script, options)
    end
    
    def run(script, options = {})
      return {} if configuration.disabled
      worker.run(script, options)
    end
    
    def alive?
      configuration.disabled ? true : worker.alive?
    end
    
    # Really only useful in development
    def discard
      worker.discard if !configuration.disabled
    end
    
    def refresh
      worker.refresh if !configuration.disabled
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
      attr_accessor :server_host
      attr_accessor :first_server_port
      attr_accessor :registry_port
      attr_accessor :jvm_init_heap_size
      attr_accessor :jvm_max_heap_size
      attr_accessor :jvm_young_heap_size
      attr_accessor :minify_libraries
      attr_accessor :server_max_bringup_time
      attr_accessor :use_rhino
      attr_accessor :disabled
      
      def initialize      
        @execution_timeout_secs = 0.5
        @server_host = "127.0.0.1"
        @first_server_port = 3030
        @registry_port = 2999
        @jvm_init_heap_size = '128m'
        @jvm_max_heap_size = '128m'
        @jvm_young_heap_size = '64m'
        @minify_libraries = true
        @server_max_bringup_time = 20 #seconds
        @use_rhino = true
        @disabled = false
        super
      end
    end
    
  private
    
    def worker
      @worker ||= configuration.use_rhino ? RhinoServerWorker.new : RacerWorker.new
    end
    
  end
    
end
