# ~/.bashrc: executed by bash(1) for non-login shells.

# Nur für interaktive Shells
case $- in
    *i*) ;;
      *) return;;
esac

# --- mise: CLI-Tools (starship, zoxide, bat, lsd, rg, fzf, node, kubectl, …) ---
# Zuerst aktivieren, damit die Tools weiter unten schon im PATH sind.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi

# --- History ---
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=10000
shopt -s histappend
shopt -s checkwinsize

# less für Nicht-Textdateien
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Fallback-Prompt (starship ersetzt ihn, falls vorhanden)
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# --- Farben ---
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# --- Editor: Neovim (über mise; git, lv, sudoedit, crontab -e … nutzen das) ---
export EDITOR=nvim
export VISUAL=nvim

# --- Eigene Aliase ---
alias ll='lsd -alF'
alias la='lsd -A'
alias cat='bat'
alias cls='clear'
alias fc='fzf --preview "bat --color=always {}"'   # überdeckt das Bash-Builtin fc (History-Editor)
alias k='kubectl'

# Benachrichtigung nach langen Befehlen:  sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# --- Completion ---
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion bash)
  complete -o default -F __start_kubectl k
fi

# --- fzf (Strg+R History, Strg+T Dateien, Alt+C Ordner) ---
export FZF_DEFAULT_OPTS="--margin=5% --padding=2% --border"
command -v fzf >/dev/null 2>&1 && eval "$(fzf --bash)"

# --- lv: „ls -la visuell“ – eigenes Repo github.com/Pohl44/lv (~/lv, eingerichtet mit ~/lv/install.sh) ---
#   lv [ordner] · Alt+L lv hier · Alt+K lv im Git-Wurzelordner · in herdr: Strg+B, F als Popup · in lv: ? / Alt+P
if [ -r ~/.local/share/lv/app/lv.bash ]; then
  . ~/.local/share/lv/app/lv.bash
  [ -r ~/.local/share/lv/app/integrations/bash-keys.bash ] && . ~/.local/share/lv/app/integrations/bash-keys.bash
fi

# --- Prompt + Navigation ---
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
command -v zoxide   >/dev/null 2>&1 && eval "$(zoxide init bash)"
