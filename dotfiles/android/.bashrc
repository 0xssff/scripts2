#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Initial shell checks
if [ $(id -ru) -eq 0 ]; then
    _ROOT=1
elif [ "$HOME" = '/data/data/com.termux/files/home' ]; then
    _TERMUX=1
fi

# Variables
EDITOR=nano
HISTSIZE=1000
HISTFILESIZE=2000

# Here begins $PATH setup spaghetti code...
if [ -z $TERMUX_SHELL ]; then
    # this variable is set in termux's /usr/etc/bash.bashrc so we can tell when
    # we're in a proot or not.
    #
    # SET PROOT PATH HERE

    (echo "$PATH" | grep -q '/busybox')  || PATH="$PATH:/busybox"
    (echo "$PATH" | grep -q "$HOME/bin") || PATH="$HOME/bin:$PATH"
else
    if [ $_ROOT ]; then
        # SET ROOT $PATH HERE

        (echo "$PATH" | grep -q '/sbin/.magisk/busybox') || PATH="/sbin/.magisk/busybox:$PATH"
    elif [ $_TERMUX ]; then
        # SET TERMUX USER $PATH HERE

        (echo "$PATH" | grep -q "$HOME/bin") || PATH="$HOME/bin:$PATH"
    fi
fi

# Fix for sometimes blank $USER variable
if [ -z "$USER" ]; then
    USER=$(whoami)
fi

# Shell PS1
PS1=$'\033[01;32m$USER\033[00m @ \033[01;34m$PWD\033[00m
--> '

# Alias
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias clear='clear -x'

# If bat installed, use this over cat. Also accounts for Debian
# now installing bat with binary name 'batcat' (wtf)
if (which batcat > /dev/null 2>&1); then
    alias cat='batcat --style=plain'
elif (which bat > /dev/null 2>&1); then
    alias cat='bat --style=plain'
fi

# Export variables
export EDITOR PATH PS1 HISTSIZE HISTFILESIZE

# Finally, user specific env setup!
if [ $_TERMUX ]; then
    # Execute user shell scripts

    logindir='/data/data/com.termux/files/home/login.d'
    for script in $(/bin/ls "$logindir"); do
        [ -x "$logindir/$script" ] && . $logindir/$script
    done
    unset script logindir _TERMUX
elif [ $_ROOT ]; then
    unset _ROOT
fi
