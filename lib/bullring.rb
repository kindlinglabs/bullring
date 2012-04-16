require 'bullring/version'
require 'bullring/worker'

module Bullring
  
  class << self
        
    attr_accessor :logger
    
    # Order is important (and relative to calls to add_library)
    def add_library_file(filename)
      worker.add_library_file(filename)
    end
    
    # Order is important (and relative to calls to add_library_script)
    def add_library(script)
      worker.add_library(script)
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
      
      def initialize      
        @execution_timeout_secs = 0.5
        @server_port = 3030
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
    
    # ESCAPE_MAP = {
    #    '\\' => '\\\\', 
    #    "\r\n" => '\n', 
    #    "\n" => '\n', 
    #    "\r" => '\n', 
    #    '"' => '\"', 
    #    "'" => "\'"
    #  }
    # 
    #  def prepare_source(source)
    #    
    #    # escape javascript characters (similar to Rails escape_javascript)
    #    source.gsub!(/(\\|\r\n|[\n\r"'])/u) {|match| ESCAPE_MAP[match] }
    # 
    #    # make sure the source string is set up to be a multiline string in JS
    #    source.gsub!(/\n/, '\ \n')   
    # 
    #    source   
    #  end
    
    # ESCAPE_MAP2 = {
    #    '\\' => '\\\\', 
    #    "\r\n" => "\n", 
    #    "\n" => "\n", 
    #    "\r" => "\n", # take these semicolons out b/c we should only use them at the end of a statement; in fact just kill comments
    #    '"' => '\"',  #need to make this surrounded by double quotes
    #    "'" => "\'"
    #  }
    #  
    #  
    #  def prep_source(source)
    #    # escape javascript characters (similar to Rails escape_javascript)
    #    source.gsub!(/(\\|\r\n|[\n\r"'])/u) {|match| ESCAPE_MAP2[match] }
    # 
    #    # make sure the source string is set up to be a multiline string in JS
    #    source.gsub!(/\n/, "\ \n")   
    # 
    #    source   
    #    
    #  end
    #  
  end
  
end
