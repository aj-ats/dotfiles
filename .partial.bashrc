# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac
cursor_style_full_block_blinking=6 # hardware cursor (blinking)
# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth
# set wsl windows path idfk for clip.exe chat says
export PATH="$PATH:/mnt/c/Windows/System32"

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

PS1='\[\e[35m\]\u@\h:\w\$ \[\e[m\]'
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi
# alias tit 
#alias tit='git'
tit() {
  git "$@"
}
# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
# pydoc 
alias pydocc="python3 -m pydoc -p 1234"
alias pdidy="python3 -m pydoc"
## aliac for rg since grep is 5x SLOWER
alias grep='rg'
#charm glow markdown cli shit alials
alias glo='glow'
#tree 
alias tre='tree'
# python3
alias python='python3'
alias py='python3'
alias flaskrun='flask run --debug --port=5000 --host=localhost'
# pretty json pipe
alias prty='python3 -m json.tool'
# tree no node modules
alias treen='tree -I node_modules'
# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
# alias4 docker prune 
#alias dockerfn='docker images -a | awk '$1 == "<none>" {print $3}' | xargs docker rmi --force' 
# docker fn func 
alias dockerfn='docker rmi -f $(docker images -aq) && docker image prune && docker volume prune && docker container prune && docker network prune'
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias neo="neofetch --ascii_distro windows95 && neofetch"
#Tmux aliass
alias ttp="tmux send-keys -t"
alias tkil="tmux kill-pane -t"
tsap() {
  tmux swap-window -s "$1" -t "$2"
}
# Alias definitions.
alias vi="nvim"

alias vo="nvim"
alias vu="nvim"
alias nivm="nvim"
# clear > cl
alias cl="clear"
# kubectl 
alias k="kubectl"
#kubectl get <>
alias kg="kubectl get"
alias kar="kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --ignore-not-found --show-kind -n"
alias kgp="kubectl get pods"
alias kgn="kubectl get nodes"
alias kgs="kubectl get services"
alias kgd="kubectl get deployments"
alias kgns="kubectl get namespaces"
alias kex="kubectl exec -it"
# kubectl describe 
alias kd="kubectl describe"
alias kdp="kubectl describe pods"
alias kdn="kubectl describe nodes"
alias k="kubectl"
# rimraf
alias rf="rm -rf --preserve-root"
# jupiter lab
alias jup="jupyter lab"
# nvim wont update fauuhk
alias nv="./squashfs-root/usr/bin/nvim"
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun
#export BUN_INSTALL="$HOME/.bun"
#export PATH=$BUN_INSTALL/bin:$PATH


. "$HOME/.cargo/env"


# set nvim as manpager
export MANPAGER='nvim +Man!'

# Load RFC SDK variabls
export SAPNWRFC_HOME=/home/andowens/Util/nwrfcsdk/nwrfcsdk-64
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SAPNWRFC_HOME/lib
export C_INCLUDE_PATH=$SAPNWRFC_HOME/include
export CPLUS_INCLUDE_PATH=$SAPNWRFC_HOME/include

. "/home/andowens/.deno/env"

# Load Angular CLI autocompletion.
source <(ng completion script)

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/andowens/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/andowens/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/andowens/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/andowens/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH="$PATH:/opt/mssql-tools18/bin"
setterm -blinking on

export PATH="$PATH:/home/andowens/.foundry/bin"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/andowens/projects/google-cloud-sdk/path.bash.inc' ]; then . '/home/andowens/projects/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/andowens/projects/google-cloud-sdk/completion.bash.inc' ]; then . '/home/andowens/projects/google-cloud-sdk/completion.bash.inc'; fi

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
[[ -r "$HOME/.grok/completions/bash/grok.bash" ]] && source "$HOME/.grok/completions/bash/grok.bash"
# <<< grok installer <<<
echo -ne "\e]12;#FFD1DC\a\e[1 q"
