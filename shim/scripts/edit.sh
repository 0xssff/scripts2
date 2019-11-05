#!/bin/sh

USER_DIR="$HOME/.user"
USER_SCRIPTS_DIR="$USER_DIR/scripts"

if [ $# -eq 0 ]; then
  printf 'please supply a filename to edit!\n'
  return 1
fi

$EDITOR "$USER_SCRIPTS_DIR/$1"