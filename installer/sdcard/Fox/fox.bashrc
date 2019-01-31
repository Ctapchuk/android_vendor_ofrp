#
# sample .bashrc file for OrangeFox
#
# HOME
export HOME=/sdcard/Fox
[ ! -d $HOME ] && mkdir -p $HOME
[ ! -d $HOME ] && export HOME=/tmp

# shell
export SHELL=/sbin/bash
export HISTFILE=$HOME/.bash_history
export PS1='\s-\v \w > '

# aliases
alias cls="clear"
alias seek='find . -name "$@"'
alias dirp="ls -a -F --color=auto -t | more"
alias dirt="ls -a -F --color=auto -t"
alias dirs="ls -a -F --color=auto -S"
alias dir="ls -all --color=auto"
alias rd="rmdir"
alias md="mkdir"
alias del="rm -i"
alias ren="mv -i"
alias copy="cp -i"
alias q="exit"
alias diskfree="df -Ph"
alias path="echo $PATH"
alias mem="cat /proc/meminfo && free"
alias ver="cat /proc/version"

# go to a neutral location
cd /tmp
#