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
    
    def isAlive
      true
    end
    
    def kill
      DRb.stop_service
      exit
    end
    
    def self.start(myPort, clientPort)
      # start up the DRb service, and wait for the DRb service to finish before exiting
      DRb.start_service "druby://localhost:2250", Bullring::RhinoServer.new
      DRb.thread.join
      #     puts "presleep"
      #     while (!DRb.current_server.alive?) 
      #       sleep(0.2)
      #       puts "sleeping"
      #     end
      # sleep(10)

      # client = DRbObject.new nil, "druby://localhost:#{clientPort}"
      # client.server_has_started
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

