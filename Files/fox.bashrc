#
# sample system-wide bashrc file for OrangeFox
#

# shell
export PS1='\s-\v \w > '

# aliases
alias cls="clear"
alias seek='find . -name "$@"'
alias dir="ls -all --color=auto"
alias rd="rmdir"
alias md="mkdir"
alias del="rm -i"
alias ren="mv -i"
alias copy="cp -i"
alias diskfree="df -Ph"
#

# go to a neutral location
cd /tmp
#
