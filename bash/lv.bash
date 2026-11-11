# shellcheck shell=bash
# --- lv: „ls -la visuell“ – ls -la im Vollbild (fzf), mit Pfeiltasten durch die Zeilen ---
#   Enter/→ öffnen · ← hoch · Strg+P Datei rechts anheften · Strg+O mit der angehefteten nebeneinander öffnen
#   Tippen filtert nach Namen · ? zeigt alle Tasten · Esc beendet (Shell bleibt im letzten Ordner)
#   Logik und fzf-Bindings: lv.d/lv-helper (neben dieser Datei)

_lv_helper="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lv.d/lv-helper"

lv() {
  local start state dir
  if [ ! -x "$_lv_helper" ]; then
    echo "lv: Hilfsskript fehlt oder ist nicht ausführbar: $_lv_helper" >&2
    return 1
  fi
  command -v fzf >/dev/null 2>&1 || { echo "lv: fzf fehlt" >&2; return 1; }
  start=$(cd -- "${1:-.}" && pwd) || return
  # Zustand (Ordner, Anheften, Ablage …) pro Aufruf, wird am Ende gelöscht
  state=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/lv.XXXXXX") || return
  LV_STATE=$state LV_HELPER=$_lv_helper "$_lv_helper" run "$start"
  dir=$(cat -- "$state/dir" 2>/dev/null)
  [ -n "$state" ] && [ -d "$state" ] && rm -rf -- "$state"
  # Ordner inzwischen weg (z. B. gelöscht)? Dann den nächsten vorhandenen darüber nehmen
  while [ -n "$dir" ] && [ ! -d "$dir" ]; do dir=$(dirname -- "$dir"); done
  cd -- "${dir:-$start}" || return
}
