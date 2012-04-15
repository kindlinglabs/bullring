require 'test_helper'
# require 'test/unit'
# require 'bullring'

class BullringTest < Test::Unit::TestCase #ActiveSupport::TestCase
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
      
  # test 'run complex full' do
  #     random_code = <<-CODE
  #     (function (pool, math, width, chunks, significance, overflow, startdenom) {
  # 
  # 
  #     //
  #     // seedrandom()
  #     // This is the seedrandom function described above.
  #     //
  # //    math['seedrandom'] = function seedrandom(seed, use_entropy) {
  # //      var key = [];
  # //      var arc4;
  # //
  # //      // Flatten the seed string or build one from local entropy if needed.
  # //      seed = mixkey(flatten(
  # //        use_entropy ? [seed, pool] :
  # //        arguments.length ? seed :
  # //        [new Date().getTime(), pool, window], 3), key);
  # //
  # //      // Use the seed to initialize an ARC4 generator.
  # //      arc4 = new ARC4(key);
  # //
  # //      // Mix the randomness into accumulated entropy.
  # //      mixkey(arc4.S, pool);
  # //
  # //      // Override Math.random
  # //
  # //      // This function returns a random double in [0, 1) that contains
  # //      // randomness in every bit of the mantissa of the IEEE 754 value.
  # //
  # //      math['random'] = function random() {  // Closure to return a random double:
  # //        var n = arc4.g(chunks);             // Start with a numerator n < 2 ^ 48
  # //        var d = startdenom;                 //   and denominator d = 2 ^ 48.
  # //        var x = 0;                          //   and no 'extra last byte'.
  # //        while (n < significance) {          // Fill up all significant digits by
  # //          n = (n + x) * width;              //   shifting numerator and
  # //          d *= width;                       //   denominator and generating a
  # //          x = arc4.g(1);                    //   new least-significant-byte.
  # //        }
  # //        while (n >= overflow) {             // To avoid rounding up, before adding
  # //          n /= 2;                           //   last byte, shift everything
  # //          d /= 2;                           //   right using integer math until
  # //          x >>>= 1;                         //   we have exactly the desired bits.
  # //        }
  # //        return (n + x) / d;                 // Form the number within [0, 1).
  # //      };
  # //
  # //      // Return the seed that was used
  # //      return seed;
  # //    };
  # //
  # //    //
  # //    // ARC4
  # //    //
  # //    // An ARC4 implementation.  The constructor takes a key in the form of
  # //    // an array of at most (width) integers that should be 0 <= x < (width).
  # //    //
  # //    // The g(count) method returns a pseudorandom integer that concatenates
  # //    // the next (count) outputs from ARC4.  Its return value is a number x
  # //    // that is in the range 0 <= x < (width ^ count).
  # //    //
  # //    /** @constructor */
  # //    function ARC4(key) {
  # //      var t, u, me = this, keylen = key.length;
  # //      var i = 0, j = me.i = me.j = me.m = 0;
  # //      me.S = [];
  # //      me.c = [];
  # //
  # //      // The empty key [] is treated as [0].
  # //      if (!keylen) { key = [keylen++]; }
  # //
  # //      // Set up S using the standard key scheduling algorithm.
  # //      while (i < width) { me.S[i] = i++; }
  # //      for (i = 0; i < width; i++) {
  # //        t = me.S[i];
  # //        j = lowbits(j + t + key[i % keylen]);
  # //        u = me.S[j];
  # //        me.S[i] = u;
  # //        me.S[j] = t;
  # //      }
  # //
  # //      // The "g" method returns the next (count) outputs as one number.
  # //      me.g = function getnext(count) {
  # //        var s = me.S;
  # //        var i = lowbits(me.i + 1); var t = s[i];
  # //        var j = lowbits(me.j + t); var u = s[j];
  # //        s[i] = u;
  # //        s[j] = t;
  # //        var r = s[lowbits(t + u)];
  # //        while (--count) {
  # //          i = lowbits(i + 1); t = s[i];
  # //          j = lowbits(j + t); u = s[j];
  # //          s[i] = u;
  # //          s[j] = t;
  # //          r = r * width + s[lowbits(t + u)];
  # //        }
  # //        me.i = i;
  # //        me.j = j;
  # //        return r;
  # //      };
  # //      // For robust unpredictability discard an initial batch of values.
  # //      // See http://www.rsa.com/rsalabs/node.asp?id=2009
  # //      me.g(width);
  # //    }
  # //
  # //    //
  # //    // flatten()
  # //    // Converts an object tree to nested arrays of strings.
  # //    //
  # //    /** @param {Object=} result 
  # //      * @param {string=} prop
  # //      * @param {string=} typ */
  # //    function flatten(obj, depth, result, prop, typ) {
  # //      result = [];
  # //      typ = typeof(obj);
  # //      if (depth && typ == 'object') {
  # //        for (prop in obj) {
  # //          if (prop.indexOf('S') < 5) {    // Avoid FF3 bug (local/sessionStorage)
  # //            try { result.push(flatten(obj[prop], depth - 1)); } catch (e) {}
  # //          }
  # //        }
  # //      }
  # //      return (result.length ? result : obj + (typ != 'string' ? '\0' : ''));
  # //    }
  # //
  # //    //
  # //    // mixkey()
  # //    // Mixes a string seed into a key that is an array of integers, and
  # //    // returns a shortened string seed that is equivalent to the result key.
  # //    //
  # //    /** @param {number=} smear 
  # //      * @param {number=} j */
  # //    function mixkey(seed, key, smear, j) {
  # //      seed += '';                         // Ensure the seed is a string
  # //      smear = 0;
  # //      for (j = 0; j < seed.length; j++) {
  # //        key[lowbits(j)] =
  # //          lowbits((smear ^= key[lowbits(j)] * 19) + seed.charCodeAt(j));
  # //      }
  # //      seed = '';
  # //      for (j in key) { seed += String.fromCharCode(key[j]); }
  # //      return seed;
  # //    }
  # //
  # //    //
  # //    // lowbits()
  # //    // A quick "n mod width" for width a power of 2.
  # //    //
  # //    function lowbits(n) { return n & (width - 1); }
  # //
  # //    //
  # //    // The following constants are related to IEEE 754 limits.
  # //    //
  # //    startdenom = math.pow(width, chunks);
  # //    significance = math.pow(2, significance);
  # //    overflow = significance * 2;
  # //
  # //    //
  # //    // When seedrandom.js is loaded, we immediately mix a few bits
  # //    // from the built-in RNG into the entropy pool.  Because we do
  # //    // not want to intefere with determinstic PRNG state later,
  # //    // seedrandom will not call math.random on its own again after
  # //    // initialization.
  # //    //
  # //    mixkey(math.random(), pool);
  # //
  # //    // End anonymous scope, and pass initial values.
  #     })(
  #       [],   // pool: entropy pool starts empty
  #       Math, // math: package containing random, pow, and seedrandom
  #       256,  // width: each RC4 output is 0 <= x < 256
  #       6,    // chunks: at least six RC4 outputs for each double
  #       52    // significance: there are 52 significant digits in a double
  #     );
  #     CODE
  #     
  #     assert_nothing_raised do
  #       Bullring.run(random_code)
  #     end
  #   end
  
  # test 'run complex' do
  #   random_code = <<-CODE
  #     (function(j,i,g,m,k,n,o){function q(b){var e,f,a=this,c=b.length,d=0,h=a.i=a.j=a.m=0;
  #       a.S=[];a.c=[];for(c||(b=[c++]);d<g;)a.S[d]=d++;for(d=0;d<g;d++)e=a.S[d],
  #       h=h+e+b[d%c]&g-1,f=a.S[h],a.S[d]=f,a.S[h]=e;a.g=function(b){var c=a.S,d=a.i+1&g-1,
  #       e=c[d],f=a.j+e&g-1,h=c[f];c[d]=h;c[f]=e;for(var i=c[e+h&g-1];--b;)d=d+1&g-1,e=c[d],
  #       f=f+e&g-1,h=c[f],c[d]=h,c[f]=e,i=i*g+c[e+h&g-1];a.i=d;a.j=f;return i};a.g(g)}
  #       function p(b,e,f,a,c){f=[];c=typeof b;if(e&&c=="object")for(a in b)if(a.indexOf("S")<5)
  #       try{f.push(p(b[a],e-1))}catch(d){}return f.length?f:b+(c!="string"?"\\0":"")}
  #       function l(b,e,f,a){b+="";for(a=f=0;a<b.length;a++){var c=e,d=a&g-1,h=(f^=e[a&g-1]*19)+
  #       b.charCodeAt(a);c[d]=h&g-1}b="";for(a in e)b+=String.fromCharCode(e[a]);return b}
  #       i.seedrandom=function(b,e){var f=[],a;b=l(p(e?[b,j]:arguments.length?b:[(new Date).getTime(),
  #       j,window],3),f);a=new q(f);l(a.S,j);i.random=function(){for(var c=a.g(m),d=o,b=0;c<k;)
  #       c=(c+b)*g,d*=g,b=a.g(1);for(;c>=n;)c/=2,d/=2,b>>>=1;return(c+b)/d};return b};o=i.pow(g,m);
  #       k=i.pow(2,k);n=k*2;l(i.random(),j)})([],Math,256,6,52);  
  #   CODE
  #   
  #   assert_nothing_raised do
  #     Bullring.run(random_code)
  #   end
  # end
  
end
