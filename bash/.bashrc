# ~/.bashrc: executed by bash(1) for non-login shells.
# This file is sourced by all interactive bash shells on startup
# shellcheck shell=bash

# Test for interactive shell; if shell is non-interactive do nothing
case $- in
    *i*) ;;
      *) return;;
esac

# disable write(1), talk(1) to terminal
command -v mesg &>/dev/null && mesg n 2>/dev/null

# number of commands to remember in command history
HISTSIZE=$((1 << 13))

# maximum number of lines contained in history file
HISTFILESIZE=$((1 << 18))

# ignore duplicate commands and leading-whitespace commands in history
HISTCONTROL=ignoreboth

# include timestamps of commands in history
HISTTIMEFORMAT='%F %T  '

# gnu_errfmt below reports shell errors in GNU error format; see
# https://www.gnu.org/prep/standards/html_node/Errors.html
shopt -s cdable_vars
shopt -s cdspell
shopt -s checkwinsize
shopt -s cmdhist
shopt -s direxpand
shopt -s dirspell
shopt -s dotglob
shopt -s extglob
shopt -s globstar
shopt -s gnu_errfmt
shopt -s histappend
shopt -s histreedit
shopt -s hostcomplete
shopt -s no_empty_cmd_completion
shopt -s nocaseglob
shopt -s progcomp
shopt -u sourcepath

# GPG agent for SSH authentication
GPG_TTY="$(tty)"
export GPG_TTY
if command -v gpgconf >/dev/null 2>&1; then
	_ssh_sock="$(gpgconf --list-dirs agent-ssh-socket)"
	if [[ -S "$_ssh_sock" ]]; then
		export SSH_AUTH_SOCK="$_ssh_sock"
	fi
	unset _ssh_sock
	gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
fi

if [ -f /etc/bash_completion ]; then
	source /etc/bash_completion
fi
if command -v terraform >/dev/null 2>&1; then
	complete -C /usr/bin/terraform terraform
fi

# fzf: fuzzy C-r history search, C-t file insertion, M-c directory change
if [[ -r /usr/share/doc/fzf/examples/key-bindings.bash ]]; then
	source /usr/share/doc/fzf/examples/key-bindings.bash
	source /usr/share/doc/fzf/examples/completion.bash
fi
if command -v rg >/dev/null 2>&1; then
	# back fzf with ripgrep: fast, honours .gitignore
	export FZF_DEFAULT_COMMAND='rg --files --hidden --glob !.git'
	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
# source supplementary aliases definitions, functions and PATH
for file in ~/.{bash_aliases,functions,path,env,bash_prompt}; do
	if [[ -r "$file" ]] && [[ -f "$file" ]]; then
		source "$file"
	fi
done

unset -v file

# Start tmux with two side-by-side panes in interactive terminals.
#
# Guards, in order: $TMUX would recurse infinitely on a nested shell; $STY
# means screen(1) is already multiplexing; NO_TMUX=1 is the escape hatch;
# TERM=linux keeps the VT consoles tmux-free so a broken .tmux.conf still
# leaves a way in.
#
# Deliberately not exec'd: on `&& exit` a tmux failure falls through to a
# normal prompt with the error visible, whereas `exec tmux` would close the
# terminal instantly and leave no way to debug it. The cost is one extra
# bash process per terminal.
#
# select-pane -L rather than -t 1 because pane-base-index makes index
# targeting config-dependent; -L is not.
if [[ -z "$TMUX" ]] && [[ -z "$STY" ]] && [[ -z "$NO_TMUX" ]] &&
	[[ "$TERM" != linux ]] && [[ "$TERM" != dumb ]] &&
	command -v tmux >/dev/null 2>&1; then
	tmux new-session -s "term-$$" \; split-window -h \; select-pane -L && exit
fi
