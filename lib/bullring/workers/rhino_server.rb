require 'rhino'
require 'drb'

module Bullring

  class RhinoServer
    
    def initialize
      @library_scripts = []
    end
    
    def add_library(script)
      @library_scripts.push(script)
    end
    
    def add_library_file(filename)
      raise NotYetImplemented
      script = read file into string
      @library_scripts.push(script)
    end
    
    def check(script, options)
      Rhino::Context.open do |context|
        context.load(File.expand_path("../../js/jslint.min.js", __FILE__))

        jslintCall = <<-RHINO_CALL
          JSLINT('#{script}', {devel: false, 
                               bitwise: true, 
                               undef: true,
                               continue: true, 
                               unparam: true, 
                               debug: true, 
                               sloppy: true, 
                               eqeq: true, 
                               sub: true, 
                               es5: true, 
                               vars: true, 
                               evil: true, 
                               white: true, 
                               forin: true, 
                               passfail: false, 
                               newcap: true, 
                               nomen: true, 
                               plusplus: true, 
                               regexp: true, 
                               maxerr: 50, 
                               indent: 4});
        RHINO_CALL
        
        context.eval(jslintCall + "JSLINT.errors")      
      end      
    end

    def run(script, options)
      Rhino::Context.open(:sealed => true, :restrictable => true) do |context|
        @library_scripts.each {|library| context.eval(library)}        
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

