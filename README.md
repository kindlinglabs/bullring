Bullring
========

Bullring is a ruby gem for safely running untrusted Javascript code.  Javascript
is the bull you want to watch but would like to protect yourself from.

Features
--------

* Runs the Javascript code in a separate process (`:rhino` runtime only)
* Lets you limit how long the untrusted code can run (`:rhino` runtime only)
* Uses therubyrhino to provide safe execution (though does not require your app to run on jruby)
* Pre-verifies the code by running it through JSLint
* Minifies the code for increased performance

Note that the `:racer` runtime option still runs JS safely but doesn't have the separate process and timeout features.  This runtime was added because in some production environments, the `:rhino` runtime option leads to instability that has not yet been debugged.  If you want to chat about this, drop me a line.

Requirements
------------

* When using the `:rhino` runtime, requires that rvm is available and that jruby has been installed through rvm (note that the rest of your code does NOT need to run on jruby).  Options for an rvm-less use are definitely conceivable, so if you have this need let's talk.

Usage
-----

(Coming soon)

Contributing
------------

(Coming soon)

Caveats
-------

Bullrings have been around a long time to keep bulls contained, but all users
should note that bulls [have gotten out before](http://tgr.ph/9tXxbc).  It is our
sincere hope that Bullring can protect you from bad side effects when running 
untrusted code.  However, Javascript is a full-blown language and Bullring is and 
contains open source software; both can have security holes, so you are urged
to be prudent when using Bullring in your application (see MIT-LICENSE for more details).
If you find a security hole, please let us know or contribute a patch.  

Copyright
---------

Bullring is Copyright 2012 Kindling Labs, LLC.  See MIT-LICENSE for more details.
