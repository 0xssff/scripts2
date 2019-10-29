#!/bin/sh

USER_DIR="$HOME/.user"
USER_SCRIPTS_DIR="$USER_DIR/scripts"

if ( echo "$PWD" | grep -q -e "^$USER_DIR" ); then
  printf "aaaaaaa please don't use this script under the $USER_DIR directory, things might break!\n"
  return 1
fi

cp "$1" "$USER_SCRIPTS_DIR" > /dev/null 2>&1 || printf "Failed to copy $1 to $USER_SCRIPTS_DIR\n"