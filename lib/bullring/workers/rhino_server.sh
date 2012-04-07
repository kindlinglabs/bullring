#!/bin/sh

# Usage: bullring_server.sh GEM_ROOT_DIR ARGS_FOR_RUBY_CALL

# Load RVM into a shell session *as a function*
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then

  # First try to load from a user install
  source "$HOME/.rvm/scripts/rvm"

elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then

  # Then try to load from a root install
  source "/usr/local/rvm/scripts/rvm"

else

  printf "ERROR: An RVM installation was not found.\n"

fi

current_gem_dir=`rvm gemdir name`

export JAVA_OPTS="-Djava.net.preferIPv4Stack=true"

rvm use jruby

export GEM_PATH=$current_gem_dir

ruby $1/bullring/workers/rhino_server.rb $2 $3 $4 $5 $6

