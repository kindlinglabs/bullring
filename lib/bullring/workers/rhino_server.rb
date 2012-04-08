require 'rubygems'
require 'rhino'
require 'drb'

module Bullring

  class RhinoServer
    def addLibrary(script)
      
    end
    
    def addLibraryFile(filename)
      
    end
    
    def check(script, options)
      
    end

    def run(script, options)
      Rhino::Context.open(:sealed => true) do |context|
        context.instruction_limit = 100000
        context.eval(script)
      end
    end
    
    def alive?
      true
    end
    
    def kill
      DRb.stop_service
      exit
    end
    
    def self.start(myPort, clientPort)
      DRb.start_service "druby://localhost:#{myPort}", Bullring::RhinoServer.new
      DRb.thread.join
    end
    
  end
end

#
# Handle command line arguments
#

command = ARGV[0]
myPort = ARGV[1]
clientPort = ARGV[2]

case command
when "start"
  Bullring::RhinoServer.start(myPort, clientPort)
end

