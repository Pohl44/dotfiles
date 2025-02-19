# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
unsetopt beep
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/itag001464/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
#
alias ll='lsd -alF'
alias la='lsd -A'
alias k='kubectl'
complete -F __start_kubectl k
alias cat='batcat'
alias cls='clear'

eval "$(starship init zsh)

eval "$(zoxide init zsh)"

eval "$(fzf --zsh)"
export PATH="$PATH:/opt/nvim-linux-x86_64/bin
