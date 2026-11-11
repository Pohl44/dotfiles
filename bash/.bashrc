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

# --- lv: „ls -la visuell“ – ls -la im Vollbild, mit Pfeiltasten durch die Zeilen ---
#   ↑↓ Zeile wählen · Enter/→ Ordner öffnen bzw. Datei öffnen · ← eine Ebene hoch
#   Strg+/ Vorschau an/aus · Tippen filtert · Esc beendet (Shell bleibt im letzten Ordner)
lv() {
  local dir out key name target
  dir=$(cd -- "${1:-.}" && pwd) || return
  while :; do
    # Spalte 1: farbige ls -la-Zeile (angezeigt), Spalte 2: exakter Dateiname (unsichtbar, für Aktionen)
    out=$(cd -- "$dir" && paste \
            <(command ls -la --color=always --group-directories-first | tail -n +2) \
            <(command ls -a1 --group-directories-first --quoting-style=literal) \
      | fzf --ansi --delimiter=$'\t' --with-nth=1 --no-sort --reverse \
            --margin=0 --padding=0 --border=none --info=inline-right \
            --prompt="$dir/ " \
            --header='Enter/→ öffnen · ← hoch · Strg+/ Vorschau · Esc beenden' \
            --preview='f={2}; if [ -d "$f" ]; then ls -la --color=always --group-directories-first -- "$f"; else bat --color=always --style=numbers --paging=never -- "$f" 2>/dev/null || file -- "$f"; fi' \
            --preview-window='right,45%' --bind='ctrl-/:toggle-preview' \
            --expect=left,right,esc) || break
    key=$(head -n1 <<<"$out")
    name=$(sed -n '2p' <<<"$out" | cut -d$'\t' -f2-)
    case "$key" in
      esc) break ;;
      left) dir=$(dirname -- "$dir"); continue ;;
    esac
    { [ -z "$name" ] || [ "$name" = "." ]; } && continue
    target="$dir/$name"
    if [ -d "$target" ]; then
      dir=$(cd -- "$target" && pwd) || continue
    elif [ "$key" != "right" ] && [ -e "$target" ]; then
      case "$(file -bL --mime-type -- "$target")" in
        text/*|inode/x-empty|application/json|application/x-shellscript) "${EDITOR:-nano}" -- "$target" ;;
        *) setsid -f xdg-open "$target" >/dev/null 2>&1 ;;
      esac
    fi
  done
  cd -- "$dir" || return
}

# --- Prompt + Navigation ---
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
command -v zoxide   >/dev/null 2>&1 && eval "$(zoxide init bash)"
