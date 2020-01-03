# History
HISTSIZE=1000
HISTFILESIZE=2000
HISTFILE=$HOME/.ksh_history

# Fixes
set -o emacs
alias cd='1> /dev/null _cd'

# Export variables
export HISTSIZE HISTFILESIZE HISTFILE

[ -z $SHELLRC_SET ] && . ~/.shellrc
