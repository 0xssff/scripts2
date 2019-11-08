# Other variables
export EDITOR=jupp

# History
export HISTSIZE=1000
export HISTFILESIZE=2000
export HISTFILE=$HOME/.ksh_history

# Shell PS1
export PS1=$'\033[01;32m\$USER\033[00m @ \033[01;34m$(if echo "$PWD" | grep -Eq "^$HOME" ; then echo "$PWD" | sed -e "s|^$HOME|~|g" ; else echo "$PWD" ; fi)\033[00m\
--> '

# Alias
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias cat='bat --style=plain'
alias clear='clear -x'

# Fixes
set -o emacs

# Load Keychain
eval `keychain --eval --agents ssh ________`

[ -z $SHELLRC_SET ] && . ~/.shellrc
