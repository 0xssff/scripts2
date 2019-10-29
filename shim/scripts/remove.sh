#!/bin/sh

USER_DIR="$HOME/.user"
USER_SCRIPTS_DIR="$USER_DIR/scripts"

if ( echo "$PWD" | grep -q -e "^$USER_DIR" ); then
  printf "aaaaaaa please don't use this script under the $USER_DIR directory, things might break!\n"
  return 1
fi

rm "$USER_SCRIPTS_DIR/$1" > /dev/null 2>&1 || printf "Failed to remove $1 from $USER_SCRIPTS_DIR\n"