#!/bin/bash
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

# Source global definitions
if [ -f /etc/bashrc ]; then
    # shellcheck source=/dev/null
    source "/etc/bashrc"
fi

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && export LESSOPEN="|lesspipe %s"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    # shellcheck disable=SC2015
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

if [[ -f "${HOME}/.bash_profile" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.bash_profile"
fi

# use a tty for gpg
# solves error: "gpg: signing failed: Inappropriate ioctl for device"
GPG_TTY=$(tty)
export GPG_TTY
# Start the gpg-agent if not already running
if ! pgrep -x -u "${USER}" gpg-agent >/dev/null 2>&1; then
    gpg-connect-agent /bye >/dev/null 2>&1
    gpg-connect-agent updatestartuptty /bye >/dev/null
fi
# Set SSH to use gpg-agent
unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
    export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
fi
# add alias for ssh to update the tty
alias ssh="gpg-connect-agent updatestartuptty /bye >/dev/null; ssh"

# powerline
if [ -f "$(command -v powerline-daemon)" ]; then
    powerline-daemon -q
    export POWERLINE_BASH_CONTINUATION=1
    export POWERLINE_BASH_SELECT=1
    # shellcheck source=/dev/null
    source "/usr/share/powerline/bash/powerline.sh"
fi

# check if there is newer kernel installed
checkkernel

# add kubectl bash autocompletion
if command -v kubectl &>/dev/null; then
	# shellcheck source=/dev/null
	source <(kubectl completion bash)
fi

# add doctl bash autocompletion
if command -v doctl &>/dev/null; then
	# shellcheck source=/dev/null
	source <(doctl completion bash)
fi

# add doctl bash autocompletion
if command -v kind &>/dev/null; then
	# shellcheck source=/dev/null
	source <(kind completion bash)
fi

# ensure proper xmodmap mapping
(xmodmap | grep locka &>/dev/null) || xmodmap "$HOME/.Xmodmap"

# Show what I need to do next
todo


