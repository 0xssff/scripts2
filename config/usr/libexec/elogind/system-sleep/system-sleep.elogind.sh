#!/bin/sh

set -e
set -x

LOG=''
USER=''
TTY=''

lock() {
    # Check xsecurelock not already running
    [ ! -z "$(pidof xsecurelock)" ] && return 1

    local _xsecurelock ret=1
    _xsecurelock='XSS_SLEEP_LOCK_FD=1 XSECURELOCK_DISCARD_FIRST_KEYPRESS=0 XSECURELOCK_FONT="Ubuntu" /usr/bin/xsecurelock'

    # Set X variables
    export XAUTHORITY="$USER/.Xauthority"
    export DISPLAY=":0"

    # Launch xsecurelock piping output to log file. If return non-zero, turns off the system
    (su "$USER" -c "sh -c '$_xsecurelock || kill -9 -1'" &) >> "$LOG" 2>&1
    return 0
}

cpu_performance() {
    # Ensure MSR module loaded
    if !(lsmod | grep -q -e '^msr'); then
        modprobe msr || return 1
    fi

    # Underclock CPU
    /usr/bin/python3 -m undervolt --verbose --core -110 --cache -110 --uncore -110 --analogio -110 --gpu -75 --temp 80 --temp-bat 80 >> "$LOG" 2>&1

    # Set CPU performce-level
    x86_energy_perf_policy --turbo-enable 1 'performance' >> "$LOG" 2>&1
}

set_env() {
    # Get xinit PID
    local xinit_pid=$(pidof xinit)
    [ -n $xinit_pid ] || return 1

    # Check xinit actually running under this PID
    (ps -p $xinit_pid > /dev/null 2>&1) || return 1

    # Set current user
    USER=$(ps -p $xinit_pid -o user --no-header)

    # Get current TTY
    TTY=$(ps -p $xinit_pid -o tty --no-header)

    # Check this is the currently logged in TTY
    [ $(printf "$TTY" | sed -e 's|^tty||') -eq $(fgconsole) ] || return 1

    # Set log file
    LOG="/var/log/elogind.sleep.${USER}"

    # If exists, try put separating new-line
    if [ -f "$LOG" ]; then
        # If not writeable, return
        [ -w "$LOG" ] || return 1

        # Put separating space
        printf '\n' >> "$LOG"
    fi

    # Write date+time to file
    printf '%s\n' "$(date +'%F %T')" >> "$LOG"

    # Ensure permissions set
    chmod 600 "$LOG"

    # All good :)
    return 0
}

# Check running as root
[ $(id -u) -ne 0 ] && return 1

# Try set necessary script environment
set_env || return 1

# Debug
printf '%s: %s\n' "$0" "$@" >> "$LOG"

# Process elogind input
case "$1" in
    pre*)
        lock
        exit $?
        ;;

    post*)
        cpu_performance
        exit $?
esac
