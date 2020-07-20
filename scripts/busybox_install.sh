#!/bin/sh

BUSYBOX='/bin/busybox.static'

if [ $# -ne 1 ]; then
    echo "Usage: ${0} <install_dir>"
    exit 1
fi

if [ ! -d "$1" ]; then
    echo "Must be a valid, accessible directory!"
    exit 1
fi

for cmd in $("${BUSYBOX}" --list); do
    ln -s "$BUSYBOX" "${1}/${cmd}"
done
