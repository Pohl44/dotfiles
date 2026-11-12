# Tastenbelegung herdr

Stand 2026-11-12, herdr 0.9.5. Config: `herdr/.config/herdr/config.toml`.

**Zwei Regeln, mehr nicht:**

1. **Alltag: `Alt` + Taste** (nur die Tasten unten)
2. **Selten: `Strg+B`, loslassen, Taste.** Das ist herdr-Standard. `Strg+B ?` zeigt alles.

Alles andere (jede `Strg`-Kombination, alle übrigen `Alt`-Tasten) gehört den Programmen: Shell, Claude Code, Neovim, lv.

## Alt (Alltag)

| Taste | Wirkung |
|---|---|
| `Alt+H` `J` `K` `L` | Bereich links / unten / oben / rechts |
| `Alt+1` … `9` | Tab 1 … 9 |
| `Alt+V` · `Alt+-` | teilen: nebeneinander · übereinander |
| `Alt+Z` | Zoom: Bereich groß / zurück |
| `Alt+Ü` | **scrollen**: Copy-Modus (`j k`, `Bild↑↓`, `/` suchen, `y` kopieren, `q` beenden) |
| `Alt+G` | Gehe zu: alle Bereiche und Agenten, `/` sucht |
| `Alt+Ö` | Dateien (lv) als Popup |

## Strg+B, dann … (selten, herdr-Standard)

| Taste | Wirkung |
|---|---|
| `c` | neuer Tab |
| `x` | Bereich schließen |
| `e` | Ausgabe des Bereichs im Editor öffnen |
| `r` | Größe ändern (dann `H J K L`, `Enter`) |
| `w` | Workspaces |
| `b` | Seitenleiste ein/aus |
| `q` | abmelden (alles läuft weiter) |
| `?` | Hilfe mit **allen** Tasten |

Die Alt-Aktionen gehen auch über den Prefix (`Strg+B h`, `Strg+B 1`, `Strg+B v` …).

## In Claude Code scrollen

`Strg+O` öffnet den Verlauf, dort `↑ ↓`, `Bild↑↓`, `Esc` zurück. Oder in herdr `Alt+Ü`.

## Prüfen

```bash
herdr config check
python3 ~/dotfiles/herdr/tests/keymap_test.py ~/dotfiles/herdr/.config/herdr/config.toml   # getrennte Test-Instanz
herdr server reload-config
git -C ~/dotfiles log --oneline -- herdr/    # ältere, umfangreichere Belegung: Commit cc9806e
```
