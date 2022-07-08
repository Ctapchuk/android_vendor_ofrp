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

# if running inside the OrangeFox terminal
[ -n "$ANDROID_SOCKET_recovery" ] && export TERM=pcansi

# aliases
alias cls="clear"
alias seek='find . -type d -path ./proc -prune -o -name "$@"'
alias dirp="ls -all --color=auto -t | more"
alias dirt="ls -all --color=auto -t"
alias dirs="ls -all --color=auto -S"
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
alias makediff="diff -u -d -w -B"
alias makediff_recurse="diff -U3 -d -w -rN"

# go to a neutral location
cd /tmp
#
