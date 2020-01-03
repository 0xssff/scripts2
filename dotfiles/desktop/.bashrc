#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

HISTSIZE=1000
HISTFILESIZE=2000

# Export variables
export HISTSIZE HISTFILESIZE

echo $SHELLRC_SET
[ -z $SHELLRC_SET ] && . ~/.shellrc
