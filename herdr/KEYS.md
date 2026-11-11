# Tastenbelegung: herdr und alles drumherum

Stand 2026-11-12, herdr 0.9.5, deutsche Tastatur. Config: `herdr/.config/herdr/config.toml`.
In herdr zeigt **Strg+B, dann ß** (oder `?`) alle Tasten; `/` filtert dort.

## Die Ebenen

| Modifikator | Ebene | Wofür |
|---|---|---|
| `Super` | Desktop (Cinnamon) | Fenster, Arbeitsflächen, `Super+V` Zwischenablage |
| `Strg+Umschalt` | Terminal (kitty) | Kopieren/Einfügen, Schriftgröße, kitty-Tabs |
| **`Alt`** | **herdr direkt** | bewegen, teilen, ansehen. Nichts, was etwas schließt. |
| **`Strg+B`, dann Taste** | **herdr komplett** (Prefix) | alles, auch Schließen und Umbenennen |
| `Strg+Buchstabe`, übrige `Alt`-Tasten | Programm im Bereich | Shell, Claude Code, Neovim, lv |

Den Prefix gibt es auf drei Wegen: `Strg+B` loslassen, dann Taste · `Strg` gedrückt halten, `B`, dann Taste ·
**rechte Strg-Taste kurz antippen**, dann Taste (xcape).

## Alt-Ebene (direkt)

Merkregel: **Umschalt = eine Ebene höher.** Bereich → Tab (waagerecht) → Workspace (senkrecht).

| Taste | Wirkung | Mit Prefix |
|---|---|---|
| `Alt+H` `J` `K` `L` oder `Alt+←` `↓` `↑` `→` | Bereich links / unten / oben / rechts | `h j k l`, Pfeile |
| `Alt+Umschalt+H` / `L` oder `Alt+Umschalt+←` / `→` | Tab zurück / vor | `p` / `n` |
| `Alt+1` … `Alt+9` | Tab 1 … 9 | `1` … `9` |
| `Alt+Umschalt+K` / `J` oder `Alt+Umschalt+↑` / `↓` | Workspace hoch / runter | `,` / `.` |
| `Alt+Ä` / `Alt+Umschalt+Ä` | nächster / vorheriger **Ä**gent | `ä` / `Umschalt+ä` |
| `Alt+A` | letzter Bereich (hin und her, auch über Tabs) | `a` |
| `Alt+G` | **G**ehe zu …: alle Bereiche und Agenten, `/` sucht | `g` |
| `Alt+W` | **W**orkspace-Navigation (Modus, siehe unten) | `w` |
| `Alt++` | neuer Tab | `c` oder `+` |
| `Alt+V` / `Alt+-` | teilen: nebeneinander / übereinander | `v` / `-` |
| `Alt+Z` | **Z**oom: Bereich groß / zurück | `z` |
| `Alt+R` | Größe ändern (**R**esize-Modus) | `r` |
| `Alt+E` | Ausgabe des Bereichs in Neovim öffnen (**E**ditor) | `e` |
| `Alt+Ü` | Copy-Modus: mit der Tastatur scrollen, suchen, kopieren | `ü` oder `[` |
| `Alt+Ö` | Dateien (lv) als Popup | `f` |
| `Alt+S` | **S**hell-Popup für einen schnellen Befehl | `Enter` |

## Nur mit Prefix (`Strg+B`, dann …)

| Taste | Wirkung |
|---|---|
| `x` · `Umschalt+X` · `Umschalt+D` | Bereich · Tab · Workspace **schließen** |
| `Umschalt+P` · `Umschalt+T` · `Umschalt+W` | Bereich · Tab · Workspace umbenennen |
| `<` · `>` | Tab nach vorn · nach hinten schieben |
| `Umschalt+H` `J` `K` `L` | Bereich mit dem Nachbarn tauschen |
| `Tab` · `Umschalt+Tab` | Bereiche der Reihe nach durchgehen |
| `Rücktaste` | Bereich leeren (Bildschirm und Verlauf) |
| `Umschalt+N` | neuer Workspace |
| `Umschalt+1` … `9` | Workspace 1 … 9 |
| `Alt+1` … `9` | Agent 1 … 9 (Reihenfolge der Seitenleiste) |
| `b` | Seitenleiste ein/aus |
| `t` | Systemmonitor (btop) als Popup |
| `o` | zur Meldung springen (nur bei herdr-eigenen Meldungen) |
| `s` · `Umschalt+R` | Einstellungen · Config neu laden |
| `q` | abmelden (alles läuft weiter, `herdr` holt es zurück) |
| `Umschalt+G` · `Umschalt+O` | Git-Worktree anlegen · öffnen |
| `ß` oder `?` oder `F1` | Hilfe |
| `Strg+B` (also zweimal) | `Strg+B` ans Programm schicken, z. B. an Claude Code |
| `Esc` | Prefix abbrechen |

Bei den Buchstabentasten darf `Strg` gedrückt bleiben (`Strg+B`, `Strg+E` wirkt wie `Strg+B`, `e`). Ausnahme: `b`, denn `Strg+B` zweimal geht ans Programm.

## Die Modi

| Modus | Hinein | Darin | Hinaus |
|---|---|---|---|
| Navigate | `Alt+W` | `↑` `↓` Workspace wählen, `Enter` übernimmt, `1`–`9` Workspace, `H J K L` Bereich, `Tab` nächster Bereich. Alle Prefix-Tasten gelten ohne Prefix. | `Esc` |
| Resize | `Alt+R` | `H` `L` Breite, `J` `K` Höhe (oder Pfeile) | `Enter`, `Esc` |
| Copy | `Alt+Ü` | `H J K L`, `w b e`, `Bild↑↓`, `Strg+U/D` bewegen · `/` `?` suchen, `n` `N` weiter · `v` oder Leertaste markieren · `y` oder `Enter` kopieren | `q`, `Esc` |
| Gehe zu | `Alt+G` | `↑` `↓` oder `j k`, `/` suchen, `b w i d` nur blockierte / arbeitende / wartende / fertige Agenten, `a` alle | `Enter`, `Esc` |
| Popup | `Alt+Ö`, `Alt+S` | Alle Tasten gehen ans Popup, herdr-Tasten greifen darin nicht. | Programm beenden |

## Was bewusst frei bleibt

| Tasten | Gehören |
|---|---|
| `Alt+P` `T` `O` | Claude Code: Modell wählen, Thinking, Fast Mode |
| `Alt+B` `F` `D` `Y` `.` `Rück` | Shell und Claude-Eingabe: wortweise springen und löschen, letztes Argument |
| `Alt+C` | fzf: in Unterordner wechseln |
| `Alt+I` `M` `N` `Q` `U` `X`, `Alt+#`, `Alt+<`, `Alt+,` | frei für Programme (lv nutzt einige davon) |
| alle `Strg+…` außer `Strg+B` | Programme |

Von herdr überdeckt und anders erreichbar:

| Verloren | Ersatz |
|---|---|
| Claude Code `Alt+J` (eingebautes Terminal) | `Alt+V` teilt in herdr einen Bereich ab |
| Claude Code `Alt+W` (Workflow-Schlüsselwort) | über `~/.claude/keybindings.json` umlegbar |
| `Alt+←` `→` wortweise springen | `Strg+←` `→` |
| Claude Code `Alt+↑` `↓` | `Strg+↑` `↓` |
| Shell `Alt+L` `R` `G` und `Alt+Ziffer` (selten gebraucht) | – |

## lv (Dateimanager, Repo `~/lv`)

Start: `Alt+Ö` (in herdr als Popup, sonst direkt in der Shell) · `Alt+Umschalt+Ö` im Git-Wurzelordner · `lv [ordner]`.
In lv: `?` Hilfe, `Alt+P` Befehlspalette. lv belegt keine Taste der herdr-Alt-Ebene (ein Test prüft das).

| Taste | Wirkung |
|---|---|
| `Enter` `→` · `←` `Rück` · `~` | öffnen · hoch · nach Hause |
| `Alt+<` · `Alt+>` | Verlauf zurück · vor |
| `Alt+B` · `Alt+Umschalt+B` | Lesezeichen setzen · anspringen |
| `Strg+C` · `Strg+X` · `Strg+V` | kopieren · ausschneiden · einfügen (wie im Dateimanager) |
| `Strg+A` · `Tab` | alle markieren · einzeln markieren |
| `Strg+H` | versteckte Dateien ein/aus |
| `F2` · `Entf` · `Alt+N` · `Alt+Umschalt+N` | umbenennen · Papierkorb · neue Datei · neuer Ordner |
| `Strg+P` · `Strg+O` | Datei rechts anheften · mit der angehefteten nebeneinander öffnen |
| `Alt+F` · `Alt+Umschalt+Z` | in Dateien suchen · Ordner per zoxide |
| `Alt+O` · `Alt+I` · `Alt+D` · `Alt+U` · `Alt+Y` | Standard-App · Eigenschaften · Git-Diff · Größe · Pfad kopieren |
| `Alt+Umschalt+E` · `Alt+T` · `Alt+Umschalt+T` | im herdr-Bereich rechts öffnen · Shell darunter · neuer herdr-Tab |
| `Alt+Umschalt+A` · `U` · `V` · `X` · `S` | packen · entpacken · Verknüpfung · ausführbar · sortieren |
| `!` (leere Suche) | Befehl ausführen, `{}` = markierte Dateien |
| `Esc` | beenden, die Shell bleibt im Ordner |

## Prüfen und zurück

```bash
herdr config check                                              # Syntax und Doppelbelegungen
python3 ~/dotfiles/herdr/tests/keymap_test.py ~/dotfiles/herdr/.config/herdr/config.toml
                                                                # 87 Tastentests in einer getrennten herdr-Instanz
python3 ~/lv/tests/smoke.py                                     # lv-Tasten
herdr server reload-config                                      # nach Änderungen (oder Strg+B, Umschalt+R)
git -C ~/dotfiles log --oneline -- herdr/                       # ältere Stände
```
