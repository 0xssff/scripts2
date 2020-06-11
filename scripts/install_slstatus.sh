#!/bin/sh

GIT_URL='https://git.suckless.org/slstatus'
GIT_DIR='slstatus'
CONFIG_FILE=''
C_FLAGS='-pipe -march=native -mtune=native'

silent() {
  $@ > /dev/null 2>&1
}

bin_check() {
  if ( ! silent $1 --version ) && ( ! silent $1 -v ) && ( ! silent $1 --help ) && ( ! silent $1 -h ) && ( ! silent which $1 ); then
    [ "$2" = '--silent' ] || printf "$1 not found!\n"
    return 1
  else
    return 0
  fi
}

initial_checks() {
  local result=0

  bin_check mktemp    || result=1
  bin_check curl      || result=1
  bin_check git       || result=1
  bin_check make      || result=1
  bin_check gcc       || result=1

  return $result
}

compile() {
  # Eenter directory
  cd "$GIT_DIR"

  # Add our cflags
  sed -i 'config.mk' -e "s|CFLAGS\s*= |CFLAGS = $C_FLAGS |"

  # Add our configuration file!
  if [ ! -z "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" 'config.h' || return 1
  fi

  # Build!
  make || return 1

  # Install!
  sudo make install || return 1

  return 0
}

main() {
  local orig_dir temp_dir

  # Perform initial checks
  initial_checks || return 1

  # Go to temporary directory
  orig_dir=$(pwd)
  temp_dir=$(mktemp -d)

  printf "Entering temp dir: $temp_dir\n"
  cd "$temp_dir"

  # Clone repository
  git clone "$GIT_URL" -b master "$GIT_DIR" || return 1

  # Compile dwm
  compile || printf 'Failed to compile / install!\n'

  # Cleanup
  cd "$orig_dir"

  printf "Cleaning temp dir: $temp_dir\n"
  sudo rm -rf "$temp_dir"

  return 0
}

case $# in
  0)
    main
    exit $?
    ;;

  2)
    if [ "$1" = '--config' ]; then
      case "$2" in
        /*)
          CONFIG_FILE="$2"
          ;;
        *)
          CONFIG_FILE="${PWD}/${2}"
          ;;
      esac
      main
      exit $?
    else
      exit 1
    fi
    ;;

  *)
    exit 1
    ;;
esac
