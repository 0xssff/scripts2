#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Variables
EDITOR=nano
HISTSIZE=1000
HISTFILESIZE=2000

# Shell PS1
PS1=$'\033[01;32m$USER\033[00m @ \033[01;34m$(if echo "$PWD" | grep -q -E "^$HOME"; then echo "$PWD" | sed -e "s|^$HOME|~|g"; else echo "$PWD"; fi)\033[00m
--> '

# User bin path
[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"

# Alias
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias cat="bat --style=plain --color auto"
alias clear='clear -x'

# Export variables
export HISTSIZE HISTFILESIZE EDITOR PS1 PATH

# Load Keychain
eval `keychain_desktop ~/.ssh/id_ecdsa`

# Motd
[ -x ~/.motd ] && . ~/.motd