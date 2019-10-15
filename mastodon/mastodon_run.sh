#!/bin/sh

HOME='/home/mastodon'
LIVE="$HOME/live"
RUN="$HOME/run"

start_mastodon_service() {
  local name=$1
  local environment=$2
  shift 2

  if ( ! status_mastodon_service $name > /dev/null 2>&1 ); then
    if [ -f "$RUN/mastodon-$name.pid" ]; then
      echo "Unused mastodon-$name.pid found, deleting..."
      rm $RUN/mastodon-$name.pid
    fi

    echo "Starting mastodon-$name"
    env $environment $@ > $RUN/mastodon-$name.log 2>&1 &
    echo "$!" > $RUN/mastodon-$name.pid
  fi
}

start_mastodon_web() {
  start_mastodon_service 'web' 'MAX_TOOT_CHARS=6942 RAILS_ENV=production PORT=3000' /home/mastodon/.rbenv/shims/bundle exec puma -C config/puma.rb
}

start_mastodon_sidekiq() {
  start_mastodon_service 'sidekiq' 'RAILS_ENV=production DB_POOL=25 MALLOC_ARENA_MAX=2' /home/mastodon/.rbenv/shims/bundle exec sidekiq -c 25
}

start_mastodon_streaming() {
  start_mastodon_service 'streaming' 'MAX_TOOT_CHARS=6942 RAILS_ENV=production PORT=4000 STREAMING_CLUSTER_NUM=1' /usr/bin/node ./streaming
}

stop_mastodon_service() {
  if [ -f "$RUN/mastodon-$1.pid" ] && ( cat $RUN/mastodon-$1.pid | grep -Eq '^[0-9]+$' ); then
    echo "Stopping mastodon-$1"
    kill $(cat $RUN/mastodon-$1.pid) > /dev/null 2>&1
    rm $RUN/mastodon-$1.pid
  fi
}

start_service() {
  # sudo check
  sudo -v || return 1

  if ( ! sudo service $1 status > /dev/null 2>&1 ); then
    echo -n "Starting service: $1 -- "
    if ( sudo service $1 start > /dev/null 2>&1 ); then
      echo 'started!'
    else
      echo 'failed to start!'
    fi
  else
    echo "Service already running: $1"
  fi
}

stop_service() {
  # sudo check
  sudo -v || return 1

  if ( sudo service $1 status > /dev/null 2>&1 ); then
    echo -n "Stopping service: $1 -- "
    if ( sudo service $1 stop > /dev/null 2>&1 ); then
      echo 'stopped!'
    else
      echo 'failed to stop!'
    fi
  else
    echo "Service not running: $1"
  fi
}

start_services() {
  start_service 'postgresql'
  start_service 'redis-server'
  start_service 'nginx'
}

start_mastodon() {
  start_mastodon_web
  start_mastodon_sidekiq
  start_mastodon_streaming
}

stop_services() {
  stop_service 'nginx'
  stop_service 'redis-server'
  stop_service 'postgresql'
}

stop_mastodon() {
  stop_mastodon_service 'web'
  stop_mastodon_service 'sidekiq'
  stop_mastodon_service 'streaming'
}

status_services() {
  local result=0

  # sudo check
  sudo -v || return 1

  echo -n 'nginx -- '
  sudo service nginx status || result=1

  echo -n 'redis-server -- '
  sudo service redis-server status || result=1

  echo -n 'postgresql -- '
  sudo service postgresql status || result=1

  return $result
}

status_mastodon_service() {
  if [ -f "$RUN/mastodon-$1.pid" ] && ( cat $RUN/mastodon-$1.pid | grep -E '^[0-9]+$' > /dev/null 2>&1 ) && ( ! ps au | grep -F "$@" | grep -Fq "$(cat $RUN/mastodon-$1.pid)"); then
    echo "mastodon-$1 -- running (PID: $(cat $RUN/mastodon-$1.pid))"
    return 0
  else
    echo "mastodon-$1 -- not running!"
    return 1
  fi
}

status_mastodon() {
  status_mastodon_service 'web'
  status_mastodon_service 'sidekiq'
  status_mastodon_service 'streaming'
}

if ( ! cd $LIVE > /dev/null 2>&1 ); then
  echo 'mastodon live directory does not exist!'
  return 1
fi

if [ ! -d "$RUN" ]; then
  echo "Creating directory: $RUN"
  if ( ! mkdir "$RUN" > /dev/null 2>&1 ); then
    echo 'Cannot create directory! Are you sure you have the right permissions?'
  fi
fi

case "$1" in
  'start-services')
    echo 'STARTING REQUIRED SERVICES...'
    start_services || return $?
    echo 'STARTED!'
    ;;

  'start-mastodon')
    echo 'STARTING MASTODON...'
    if ( ! status_services > /dev/null 2>&1 ); then
      echo 'Required services are not running, starting!'
      start-services
      return 1
    fi
    start_mastodon || return $?
    echo 'STARTED!'
    ;;

  'stop')
    echo 'STOPPING MASTODON...'
    stop_mastodon || return $?

    if [ "$2" = '--all' ]; then
      stop_services || return $?
    fi

    echo 'STOPPED!'
    ;;

  'restart')
    echo 'RESTARTING MASTODON...'
    stop_mastodon || return $?

    if [ "$2" = '--all' ]; then
      stop_services || return $?
      start_services || return $?
    fi

    start_mastodon || return $?
    echo 'RESTARTED!'
    ;;

  'status')
    if [ "$2" = '--all' ]; then
      status_services
    fi

    status_mastodon
    ;;
esac
