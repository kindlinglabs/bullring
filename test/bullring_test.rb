require 'test_helper'
require 'logger'

if false
  Bullring.logger = Logger.new('bullring_test_log.txt')
  Bullring.logger.level = Logger::DEBUG
end

class BullringTest < Test::Unit::TestCase 
  
  def setup
    Bullring.configure do |config|
      #config.use_rhino = false
    end
  end
  
  test "truth" do
    assert_kind_of Module, Bullring
  end
  
  test "run 1" do
    assert_nothing_raised{Bullring.run("3")}
  end
  
  test "run multiline" do
    assert_nothing_raised do 
      result = Bullring.run("3;\r\n4")
      assert_equal 4, result
    end
  end

  test 'run 2' do
    code = <<-CODE
      x = 'howdy';
      (function(arg){return arg+' there';})(x)
    CODE
    
    assert_nothing_raised do
      Bullring.run(code)
    end
  end
  
  test 'run complex a' do
    random_code = <<-CODE
      (function(j,i,g,m,k,n,o){})([],Math,256,6,52);  
    CODE
    
    assert_nothing_raised do
      Bullring.run(random_code)
    end
  end
 
    test 'run complex full oneline' do
      random_code = <<-CODE
      (function (pool, math, width, chunks, significance, overflow, startdenom) {})([], Math, 256,6,52);
      CODE

      assert_nothing_raised do
        Bullring.run(random_code)
      end
    end
 
    test 'run complex full cut' do
      random_code = <<-CODE
      (function (pool, math, width, chunks, significance, overflow, startdenom) {

      })(
        [],   // pool: entropy pool starts empty
        Math, // math: package containing random, pow, and seedrandom
        256,  // width: each RC4 output is 0 <= x < 256
        6,    // chunks: at least six RC4 outputs for each double
        52    // significance: there are 52 significant digits in a double
      );
      CODE

      assert_nothing_raised do
        Bullring.run(random_code)
      end
    end 
    
    test 'run 3' do
      code = <<-CODE
        var myFunc = function(a,b,c) {
          d = a+b;
          return c*d;
        }
        
        myFunc(1,2,4);
      CODE
      
      assert_nothing_raised do
        result = Bullring.run(code)
        assert_equal 12, result
      end
    end
      
    test 'library' do
      library = <<-LIBRARY
        var QB = (function (my) {
          my.return4 = function() {
              return 4;
          };

          return my;
        }(QB || {}));
        
      LIBRARY
      
      code = <<-CODE
        QB.return4();      
      CODE
      
      Bullring.add_library('testlib', library)
      
      result = Bullring.run(code, {"library_names" => ['testlib']})
      assert_equal 4, result      
    end
  
  test 'run complex' do
    random_code = <<-CODE
      (function(j,i,g,m,k,n,o){function q(b){var e,f,a=this,c=b.length,d=0,h=a.i=a.j=a.m=0;
        a.S=[];a.c=[];for(c||(b=[c++]);d<g;)a.S[d]=d++;for(d=0;d<g;d++)e=a.S[d],
        h=h+e+b[d%c]&g-1,f=a.S[h],a.S[d]=f,a.S[h]=e;a.g=function(b){var c=a.S,d=a.i+1&g-1,
        e=c[d],f=a.j+e&g-1,h=c[f];c[d]=h;c[f]=e;for(var i=c[e+h&g-1];--b;)d=d+1&g-1,e=c[d],
        f=f+e&g-1,h=c[f],c[d]=h,c[f]=e,i=i*g+c[e+h&g-1];a.i=d;a.j=f;return i};a.g(g)}
        function p(b,e,f,a,c){f=[];c=typeof b;if(e&&c=="object")for(a in b)if(a.indexOf("S")<5)
        try{f.push(p(b[a],e-1))}catch(d){}return f.length?f:b+(c!="string"?"\\0":"")}
        function l(b,e,f,a){b+="";for(a=f=0;a<b.length;a++){var c=e,d=a&g-1,h=(f^=e[a&g-1]*19)+
        b.charCodeAt(a);c[d]=h&g-1}b="";for(a in e)b+=String.fromCharCode(e[a]);return b}
        i.seedrandom=function(b,e){var f=[],a;b=l(p(e?[b,j]:arguments.length?b:[(new Date).getTime(),
        j,window],3),f);a=new q(f);l(a.S,j);i.random=function(){for(var c=a.g(m),d=o,b=0;c<k;)
        c=(c+b)*g,d*=g,b=a.g(1);for(;c>=n;)c/=2,d/=2,b>>>=1;return(c+b)/d};return b};o=i.pow(g,m);
        k=i.pow(2,k);n=k*2;l(i.random(),j)})([],Math,256,6,52);  
    CODE
    
    assert_nothing_raised do
      Bullring.run(random_code)
    end
  end
  
  test 'check' do
    code = <<-CODE
      a = 42;
      y = 2*a;
    CODE
    
    assert_nothing_raised do
      Bullring.check(code)
    end
      
  end
  
end
