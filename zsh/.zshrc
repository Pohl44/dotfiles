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

# --- mise activation (robust) ---
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)" || true
fi

# --- direnv hook ---
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

alias ll='lsd -alF'
alias la='lsd -A'
alias k='kubectl'
if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion zsh)
    compdef _kubectl k
fi
alias cat='bat'
alias cls='clear'

eval "$(starship init zsh)"

eval "$(zoxide init zsh)"

eval "$(fzf --zsh)"
