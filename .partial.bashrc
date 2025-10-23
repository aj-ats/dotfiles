#alias tit='git'
tit() {
  git "$@"
}
# colored gcc warnings and errors
#export gcc_colors='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
# pydoc 
pydocc="python3 -m pydoc -p 1234"
pdidy="python3 -m pydoc"
## aliac for rg since grep is 5x slower
alias grep='rg'
#charm glow markdown cli shit alials
alias glo='glow'
#tree 
alias tre='tree'
# python3
alias python='python3'
alias py='python3'
# pretty json pipe
alias prty='python3 -m json.tool'
# tree no node modules
alias treen='tree -i node_modules'
# some more ls aliases
alias ll='ls -alf'
alias la='ls -a'
alias l='ls -cf'
# alias4 docker prune 
#alias dockerfn='docker images -a | awk '$1 == "<none>" {print $3}' | xargs docker rmi --force' 
# docker fn func 
alias dockerfn='docker rmi -f $(docker images -aq) && docker image prune && docker volume prune && docker container prune && docker network prune'
# add an "alert" alias for long running commands.  use like so:
#   sleep 10; alert
alias neo="neofetch --ascii_distro windows95 && neofetch"
#tmux aliass
alias ttp="tmux send-keys -t"
alias tkil="tmux kill-pane -t"
tsap() {
  tmux swap-window -s "$1" -t "$2"
}
# alias definitions.
alias vi="nvim"
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
#
