#!/bin/bash

# Usage: bullring_server.sh GEM_ROOT_DIR ARGS_FOR_RUBY_CALL

BULLRING_ROOT=$1
DAEMON_CMD=$2
HOST=$3
REGISTRY_PORT=$4
INIT_HEAP_SIZE=$5     # Xms, e.g. 128m
MAX_HEAP_SIZE=$6      # Xmx, e.g. 128m
YOUNG_HEAP_SIZE=$7    # Xmn, e.g. 92m

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

export JAVA_OPTS="-Djava.net.preferIPv4Stack=true"

rhino_gem_dir=`bundle show therubyrhino`

rvm use jruby
ruby_bin=`which ruby`

GEM_HOME=
IRBRC=
BUNDLE_GEMFILE=
GEM_PATH=
RUBYOPT=
BUNDLE_BIN_PATH=

$ruby_bin -J-Xmn$YOUNG_HEAP_SIZE -J-Xms$INIT_HEAP_SIZE -J-Xmx$MAX_HEAP_SIZE \
          -J-server \
          -I $rhino_gem_dir/lib \
          $BULLRING_ROOT/bullring/workers/rhino_server.rb $DAEMON_CMD $HOST $REGISTRY_PORT