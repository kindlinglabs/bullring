

module Bullring

  class JSError < StandardError; end

  class Helper
    def self.jslint_call(script)
       jslintCall = <<-RACER_CALL
          JSLINT("#{prepare_source(script)}", {devel: false, 
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
                               indent: 4}); JSLINT.errors
        RACER_CALL
    end
    
    ESCAPE_MAP = {
      '\\' => '\\\\', 
      "\r\n" => '\n', 
      "\n" => '\n', 
      "\r" => '\n', 
      '"' => '\"', 
      "'" => '\''
    }
          
    def self.prepare_source(source) 
     # escape javascript characters (similar to Rails escape_javascript)
     source.gsub!(/(\\|\r\n|[\n\r"'])/u) {|match| ESCAPE_MAP[match] }
     source   
    end
    
  end
  
end