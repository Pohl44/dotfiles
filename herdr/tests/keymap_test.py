#!/usr/bin/env python3
"""Regressionstest für die herdr-Tastenbelegung.

Startet eine GETRENNTE herdr-Instanz (eigener XDG_CONFIG_HOME, eigenes Socket) in einem
Pseudo-Terminal, spielt Tasten so ein, wie kitty sie im Kitty-Tastaturprotokoll auf einer
deutschen Tastatur sendet, und prüft die Wirkung über die herdr-API.

Aufruf:  keymap_test.py <pfad/zur/config.toml> [-v]
Die laufende herdr-Sitzung wird nicht berührt.
"""
import fcntl
import json
import os
import pty
import re
import select
import shutil
import struct
import subprocess
import sys
import tempfile
import termios
import threading
import time

VERBOSE = "-v" in sys.argv
CONFIG = os.path.abspath([a for a in sys.argv[1:] if not a.startswith("-")][0])

SHIFT, ALT, CTRL = 1, 2, 4
# Deutsche Tastatur: Zeichen -> Zeichen derselben Taste im US-Layout (kitty meldet es als "base layout key")
DE_BASE = {"ö": ";", "ä": "'", "ü": "[", "+": "]", "#": "\\", "-": "/", "ß": "-", "z": "y", "y": "z"}
# Umschalt-Ebene der deutschen Tastatur
DE_SHIFT = {"ß": "?", "<": ">", "1": "!", "2": '"', "3": "§", "4": "$", "5": "%", "6": "&", "7": "/",
            "8": "(", "9": ")", "+": "*", "#": "'", ",": ";", ".": ":", "-": "_", "ä": "Ä", "ö": "Ö", "ü": "Ü"}
ARROWS = {"left": "D", "right": "C", "up": "A", "down": "B"}
FUNC = {"enter": (13, "\r"), "tab": (9, "\t"), "backspace": (127, "\x7f"), "esc": (27, None)}


class Host:
    """Spielt das äußere Terminal (kitty) für den herdr-Client."""

    def __init__(self, workdir, env):
        self.buf = b""
        self.lock = threading.Lock()
        self.flags_stack = [0]
        self.alive = True
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            os.chdir(workdir)
            os.execvpe("herdr", ["herdr"], env)
        fcntl.ioctl(self.fd, termios.TIOCSWINSZ, struct.pack("HHHH", 50, 190, 0, 0))
        threading.Thread(target=self._reader, daemon=True).start()

    @property
    def flags(self):
        return self.flags_stack[-1]

    def _reader(self):
        pending = b""
        while self.alive:
            try:
                r, _, _ = select.select([self.fd], [], [], 0.05)
                if not r:
                    continue
                data = os.read(self.fd, 65536)
            except OSError:
                return
            if not data:
                return
            with self.lock:
                self.buf += data
            pending = (pending + data)[-4096:]
            pending = self._answer(pending)

    def _answer(self, data):
        # Tastaturprotokoll: push/pop/set mitschreiben, Abfragen beantworten
        for m in re.finditer(rb"\x1b\[(?:>(\d*)u|<(\d*)u|=(\d+)(?:;(\d))?u|\?u|c|\?1016\$p|>q)", data):
            tok = m.group(0)
            if tok.startswith(b"\x1b[>") and tok.endswith(b"u"):
                self.flags_stack.append(int(m.group(1) or 0))
            elif tok.startswith(b"\x1b[<"):
                for _ in range(int(m.group(2) or 1)):
                    if len(self.flags_stack) > 1:
                        self.flags_stack.pop()
            elif tok.startswith(b"\x1b[="):
                self.flags_stack[-1] = int(m.group(3))
            elif tok == b"\x1b[?u":
                os.write(self.fd, b"\x1b[?%du" % self.flags)
            elif tok == b"\x1b[c":
                os.write(self.fd, b"\x1b[?62;c")
            elif tok == b"\x1b[?1016$p":
                os.write(self.fd, b"\x1b[?1016;0$y")
            elif tok == b"\x1b[>q":
                os.write(self.fd, b"\x1bP>|kitty(0.50.0)\x1b\\")
        # nur einen unvollständigen Rest behalten
        last = data.rfind(b"\x1b")
        return data[last:] if last >= 0 and len(data) - last < 12 else b""

    def take(self):
        with self.lock:
            out, self.buf = self.buf, b""
        return out

    def text_since(self, wait=0.5):
        time.sleep(wait)
        raw = self.take()
        txt = re.sub(rb"\x1b\[[0-9;:?<>=$]*[a-zA-Z]|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)|\x1b[()][A-Z0-9]", b"", raw)
        return txt.decode("utf-8", "replace")

    # --- Tasten kodieren wie kitty -------------------------------------------------
    def key(self, spec):
        """spec z. B. 'alt+h', 'alt+shift+ä', 'ctrl+b', 'shift+ß', 'alt+left', 'enter', '<'."""
        parts = spec.split("+") if spec != "+" and not spec.endswith("++") else spec[:-1].rstrip("+").split("+") + ["+"]
        parts = [p for p in parts if p != ""]
        mods = 0
        while len(parts) > 1 and parts[0] in ("shift", "alt", "ctrl"):
            mods |= {"shift": SHIFT, "alt": ALT, "ctrl": CTRL}[parts.pop(0)]
        k = {"minus": "-", "plus": "+", "comma": ",", "period": "."}.get(parts[0], parts[0])
        report_all = bool(self.flags & 8)
        with_text = bool(self.flags & 16)
        if k in ARROWS:
            seq = f"\x1b[1;{1 + mods}{ARROWS[k]}" if mods else f"\x1b[{ARROWS[k]}"
        elif k in FUNC:
            code, legacy = FUNC[k]
            if k == "tab" and mods == SHIFT and not report_all:
                seq = "\x1b[Z"
            elif mods or report_all or legacy is None:
                seq = f"\x1b[{code};{1 + mods}u" if mods else f"\x1b[{code}u"
            else:
                seq = legacy
        else:
            shifted = DE_SHIFT.get(k, k.upper() if k.isalpha() else None) if mods & SHIFT else None
            text_char = shifted if (mods & SHIFT and shifted) else k
            only_shift = (mods & ~SHIFT) == 0
            if only_shift and not report_all:
                seq = text_char                       # normales Tippen kommt als Text
            else:
                field = str(ord(k))
                base = DE_BASE.get(k)
                if shifted or base:
                    field += ":" + (str(ord(shifted)) if shifted else "")
                    if base:
                        field += ":" + str(ord(base))
                seq = f"\x1b[{field}"
                text = f";{ord(text_char)}" if (with_text and only_shift) else ""
                if mods or text:
                    seq += f";{1 + mods}" if mods else ";"
                    seq += text
                seq += "u"
        if VERBOSE:
            print(f"      taste {spec!r} flags={self.flags} -> {seq!r}")
        os.write(self.fd, seq.encode())
        time.sleep(0.12)

    def keys(self, *specs, wait=0.45):
        for s in specs:
            self.key(s)
        time.sleep(wait)

    def type(self, text):
        for ch in text:
            if ch == "\n":
                self.key("enter")
            elif self.flags & 8:
                os.write(self.fd, f"\x1b[{ord(ch)};;{ord(ch)}u".encode())
                time.sleep(0.01)
            else:
                os.write(self.fd, ch.encode())
        time.sleep(0.3)

    def close(self):
        self.alive = False
        try:
            os.close(self.fd)
        except OSError:
            pass


class Test:
    def __init__(self):
        self.root = tempfile.mkdtemp(prefix="herdr-keytest.")
        cfgdir = os.path.join(self.root, "cfg", "herdr")
        os.makedirs(cfgdir)
        shutil.copy(CONFIG, os.path.join(cfgdir, "config.toml"))
        self.work = os.path.join(self.root, "work dir")
        os.makedirs(self.work)
        self.marker = os.path.join(self.root, "editor-called")
        editor = os.path.join(self.root, "fake-editor")
        with open(editor, "w") as f:
            f.write(f"#!/bin/sh\necho \"$@\" > '{self.marker}'\n")
        os.chmod(editor, 0o755)
        env = {k: v for k, v in os.environ.items() if not k.startswith("HERDR_")}
        env.update(XDG_CONFIG_HOME=os.path.join(self.root, "cfg"), TERM="xterm-kitty",
                   EDITOR=editor, VISUAL=editor, COLUMNS="190", LINES="50")
        env.pop("KITTY_WINDOW_ID", None)
        # XDG_CONFIG_HOME zeigt auf den Testordner: mise braucht trotzdem seine echte Konfiguration
        env.setdefault("MISE_CONFIG_DIR", os.path.expanduser("~/.config/mise"))
        self.env = env
        self.sock = os.path.join(cfgdir, "herdr.sock")
        self.results = []
        self.host = Host(self.work, env)

    # --- API -------------------------------------------------------------------
    def api(self, *args):
        out = subprocess.run(["herdr", *args], env=self.env, capture_output=True, text=True, timeout=15)
        try:
            return json.loads(out.stdout)["result"]
        except Exception:
            return {"_raw": out.stdout + out.stderr}

    def ws(self):
        return self.api("workspace", "list").get("workspaces", [])

    def focused_ws(self):
        return next((w["workspace_id"] for w in self.ws() if w.get("focused")), None)

    def tabs(self, ws=None):
        return self.api("tab", "list", "--workspace", ws or self.focused_ws()).get("tabs", [])

    def focused_tab(self):
        return next((t["tab_id"] for t in self.tabs() if t.get("focused")), None)

    def panes(self, ws=None):
        return self.api("pane", "list", "--workspace", ws or self.focused_ws()).get("panes", [])

    def focused_pane(self):
        tab = self.focused_tab()
        return next((p["pane_id"] for p in self.panes() if p.get("focused") and p["tab_id"] == tab), None)

    def layout(self):
        return self.api("pane", "layout", "--pane", self.focused_pane()).get("layout", {})

    def rect(self, pane):
        return next((p["rect"] for p in self.layout().get("panes", []) if p["pane_id"] == pane), None)

    def pane_text(self, pane):
        out = subprocess.run(["herdr", "pane", "read", pane, "--source", "recent-unwrapped", "--lines", "40"],
                             env=self.env, capture_output=True, text=True, timeout=15)
        return out.stdout

    # --- Auswertung ------------------------------------------------------------
    def check(self, name, ok, detail=""):
        self.results.append((name, bool(ok)))
        print(f"{'OK  ' if ok else 'FAIL'} {name}" + (f"   [{detail}]" if detail and (not ok or VERBOSE) else ""))

    def wait_server(self):
        for _ in range(80):
            if os.path.exists(self.sock) and self.ws():
                return True
            time.sleep(0.25)
        return False

    def stop(self):
        self.host.close()
        env = dict(self.env, HERDR_SOCKET_PATH=self.sock)   # ausdrücklich NUR die Test-Instanz
        subprocess.run(["herdr", "server", "stop"], env=env, capture_output=True, timeout=20)
        time.sleep(0.5)
        shutil.rmtree(self.root, ignore_errors=True)


def run(t):
    h = t.host
    t.check("Test-Instanz gestartet (getrenntes Socket)", t.wait_server(), t.sock)
    time.sleep(1.5)
    h.keys("esc")
    h.take()
    t.check("Kitty-Tastaturprotokoll vom Client angefordert", h.flags & 1, f"flags={h.flags}")
    p0 = t.focused_pane()
    t.check("Start: 1 Workspace, 1 Tab, 1 Bereich", len(t.ws()) == 1 and len(t.tabs()) == 1 and len(t.panes()) == 1)

    # ── Alt-Ebene: Bereiche ─────────────────────────────────────────────────
    h.keys("alt+v", wait=0.9)
    t.check("Alt+V teilt nebeneinander", len(t.panes()) == 2)
    p1 = t.focused_pane()
    h.keys("alt+h"); t.check("Alt+H Bereich links", t.focused_pane() == p0)
    h.keys("alt+l"); t.check("Alt+L Bereich rechts", t.focused_pane() == p1)
    h.keys("alt+left"); t.check("Alt+← Bereich links", t.focused_pane() == p0)
    h.keys("alt+right"); t.check("Alt+→ Bereich rechts", t.focused_pane() == p1)
    h.keys("alt+minus", wait=0.9)
    t.check("Alt+- teilt übereinander", len(t.panes()) == 3)
    p2 = t.focused_pane()
    h.keys("alt+k"); t.check("Alt+K Bereich oben", t.focused_pane() == p1)
    h.keys("alt+j"); t.check("Alt+J Bereich unten", t.focused_pane() == p2)
    h.keys("alt+up"); t.check("Alt+↑ Bereich oben", t.focused_pane() == p1)
    h.keys("alt+down"); t.check("Alt+↓ Bereich unten", t.focused_pane() == p2)
    h.keys("alt+a"); t.check("Alt+A letzter Bereich (hin)", t.focused_pane() == p1)
    h.keys("alt+a"); t.check("Alt+A letzter Bereich (her)", t.focused_pane() == p2)
    h.keys("alt+z"); t.check("Alt+Z Zoom an", t.layout().get("zoomed") is True)
    h.keys("alt+z"); t.check("Alt+Z Zoom aus", t.layout().get("zoomed") is False)

    # Resize-Modus
    w_before = t.rect(p0)["width"]
    h.keys("alt+h")
    h.take(); h.key("alt+r")
    t.check("Alt+R Resize-Modus", "RESIZE" in h.text_since())
    h.keys("l", "l", "l", "enter", wait=0.6)
    t.check("Resize: L verbreitert, Enter beendet", t.rect(p0)["width"] > w_before, f"{w_before} -> {t.rect(p0)['width']}")

    # Copy-Modus
    h.take(); h.key("alt+ü")
    t.check("Alt+Ü Copy-Modus", "COPY" in h.text_since())
    h.keys("q")
    h.take(); h.keys("ctrl+b", "ü", wait=0.1)
    t.check("Prefix Ü Copy-Modus", "COPY" in h.text_since())
    h.keys("q")

    # ── Prefix-Ebene: Bereiche ──────────────────────────────────────────────
    h.keys("ctrl+b", "l"); t.check("Prefix L Bereich rechts", t.focused_pane() in (p1, p2))
    h.keys("ctrl+b", "ctrl+h"); t.check("Prefix Strg+H (Strg gehalten) Bereich links", t.focused_pane() == p0)
    h.keys("ctrl+b", "right"); t.check("Prefix → Bereich rechts", t.focused_pane() in (p1, p2))
    h.keys("ctrl+b", "ctrl+j"); h.keys("ctrl+b", "ctrl+k")
    t.check("Prefix Strg+J / Strg+K (Strg gehalten)", t.focused_pane() == p1)
    r_before = t.rect(p1)
    h.keys("ctrl+b", "shift+j", wait=0.7)
    t.check("Prefix Umschalt+J tauscht Bereiche", t.rect(p1) != r_before, f"{r_before} -> {t.rect(p1)}")
    h.keys("ctrl+b", "shift+k", wait=0.7)
    before = t.focused_pane(); h.keys("ctrl+b", "tab")
    t.check("Prefix Tab nächster Bereich", t.focused_pane() != before)

    # ── Tabs ────────────────────────────────────────────────────────────────
    tab1 = t.focused_tab()
    h.keys("alt++", wait=0.6); h.type("zwei\n"); time.sleep(0.6)
    t.check("Alt++ neuer Tab", len(t.tabs()) == 2, str([x["label"] for x in t.tabs()]))
    tab2 = t.focused_tab()
    h.keys("ctrl+b", "c", wait=0.6); h.type("drei\n"); time.sleep(0.6)
    t.check("Prefix C neuer Tab", len(t.tabs()) == 3)
    tab3 = t.focused_tab()
    h.keys("alt+1"); t.check("Alt+1 Tab 1", t.focused_tab() == tab1)
    h.keys("alt+3"); t.check("Alt+3 Tab 3", t.focused_tab() == tab3)
    h.keys("alt+shift+h"); t.check("Alt+Umschalt+H Tab zurück", t.focused_tab() == tab2)
    h.keys("alt+shift+l"); t.check("Alt+Umschalt+L Tab vor", t.focused_tab() == tab3)
    h.keys("alt+shift+left"); t.check("Alt+Umschalt+← Tab zurück", t.focused_tab() == tab2)
    h.keys("alt+shift+right"); t.check("Alt+Umschalt+→ Tab vor", t.focused_tab() == tab3)
    h.keys("ctrl+b", "p"); t.check("Prefix P Tab zurück", t.focused_tab() == tab2)
    h.keys("ctrl+b", "ctrl+n"); t.check("Prefix Strg+N Tab vor", t.focused_tab() == tab3)
    h.keys("ctrl+b", "2"); t.check("Prefix 2 Tab 2", t.focused_tab() == tab2)
    order = [x["tab_id"] for x in t.tabs()]
    h.keys("ctrl+b", "<", wait=0.6)
    t.check("Prefix < schiebt Tab nach vorn", [x["tab_id"] for x in t.tabs()] == [tab2, tab1, tab3], str([x["tab_id"] for x in t.tabs()]))
    h.keys("ctrl+b", "shift+<", wait=0.6)
    t.check("Prefix > schiebt Tab nach hinten", [x["tab_id"] for x in t.tabs()] == order)

    # ── Agenten (zwei Bereiche als Agenten melden) ──────────────────────────
    h.keys("alt+1")
    for pane in (p0, p2):
        t.api("pane", "report-agent", pane, "--source", "keytest", "--agent", "claude", "--state", "idle")
    time.sleep(0.6)
    h.keys("alt+h"); h.keys("alt+h")
    start = t.focused_pane()
    h.keys("alt+ä", wait=0.6); a1 = t.focused_pane()
    h.keys("alt+ä", wait=0.6); a2 = t.focused_pane()
    t.check("Alt+Ä nächster Agent", {a1, a2} == {p0, p2}, f"start={start} a1={a1} a2={a2}")
    h.keys("alt+shift+ä", wait=0.6)
    t.check("Alt+Umschalt+Ä vorheriger Agent", t.focused_pane() == a1)
    h.keys("ctrl+b", "ä", wait=0.6); t.check("Prefix Ä nächster Agent", t.focused_pane() == a2)
    h.keys("ctrl+b", "shift+ä", wait=0.6); t.check("Prefix Umschalt+Ä vorheriger Agent", t.focused_pane() == a1)
    h.keys("ctrl+b", "alt+2", wait=0.6); second = t.focused_pane()
    h.keys("ctrl+b", "alt+1", wait=0.6); first = t.focused_pane()
    t.check("Prefix Alt+1 / Alt+2 Agent nach Nummer", {first, second} == {p0, p2} and first != second, f"{first} {second}")

    # ── Workspaces ──────────────────────────────────────────────────────────
    ws1 = t.focused_ws()
    h.keys("ctrl+b", "shift+n", wait=1.2)
    t.check("Prefix Umschalt+N neuer Workspace", len(t.ws()) == 2)
    ws2 = t.focused_ws()
    h.keys("alt+shift+k", wait=0.6); t.check("Alt+Umschalt+K Workspace hoch", t.focused_ws() == ws1)
    h.keys("alt+shift+j", wait=0.6); t.check("Alt+Umschalt+J Workspace runter", t.focused_ws() == ws2)
    h.keys("alt+shift+up", wait=0.6); t.check("Alt+Umschalt+↑ Workspace hoch", t.focused_ws() == ws1)
    h.keys("alt+shift+down", wait=0.6); t.check("Alt+Umschalt+↓ Workspace runter", t.focused_ws() == ws2)
    h.keys("ctrl+b", ",", wait=0.6); t.check("Prefix , vorheriger Workspace", t.focused_ws() == ws1)
    h.keys("ctrl+b", ".", wait=0.6); t.check("Prefix . nächster Workspace", t.focused_ws() == ws2)
    h.keys("ctrl+b", "shift+1", wait=0.6); t.check("Prefix Umschalt+1 Workspace 1", t.focused_ws() == ws1)

    # ── Modi und Überblendungen ─────────────────────────────────────────────
    h.take(); h.key("alt+w")
    t.check("Alt+W Navigate-Modus", "NAVIGATE" in h.text_since())
    h.keys("esc")
    h.take(); h.keys("ctrl+b", "w", wait=0.1)
    t.check("Prefix W Navigate-Modus", "NAVIGATE" in h.text_since())
    before = t.focused_pane(); h.keys("l", "h", "l")
    t.check("Navigate: H/L ohne Prefix, Modus bleibt offen", t.focused_pane() != before or len(t.panes()) > 1)
    h.keys("esc")
    h.take(); h.key("alt+g"); txt = h.text_since(0.7)
    t.check("Alt+G Gehe-zu-Auswahl", re.search(r"(?i)go ?to|search|filter", txt) is not None, txt[-200:].replace("\n", " "))
    h.keys("esc")
    h.take(); h.keys("ctrl+b", "ß", wait=0.1); txt = h.text_since(0.7)
    t.check("Prefix ß Hilfe", re.search(r"(?i)keybind|help", txt) is not None)
    h.take(); h.keys("/"); h.type("lv"); txt = h.text_since(0.7)
    t.check("Hilfe nennt den eigenen Befehl mit Beschreibung", "Dateien (lv)" in txt, re.sub(r"\s+", " ", txt)[-300:])
    h.keys("esc")
    h.keys("esc")
    h.take(); h.keys("ctrl+b", "shift+ß", wait=0.1); txt = h.text_since(0.7)
    t.check("Prefix ? Hilfe", re.search(r"(?i)keybind|help", txt) is not None)
    h.keys("esc")
    h.take(); h.key("ctrl+b")
    t.check("Strg+B zeigt PREFIX", "PREFIX" in h.text_since())
    h.keys("esc")

    # ── Verlauf ─────────────────────────────────────────────────────────────
    h.keys("alt+e", wait=1.5)
    t.check("Alt+E öffnet die Ausgabe im Editor", os.path.exists(t.marker))
    h.keys("enter", wait=0.5)

    # ── Popups ──────────────────────────────────────────────────────────────
    proof = os.path.join(t.root, "popup-pwd")
    h.keys("alt+s", wait=1.8)
    h.type(f" pwd > '{proof}'; exit\n"); time.sleep(1.2)
    got = open(proof).read().strip() if os.path.exists(proof) else ""
    t.check("Alt+S Shell-Popup im Ordner des Bereichs", got == t.work, got)
    h.take(); h.keys("alt+ö", wait=2.5); txt = h.text_since(0.5)
    t.check("Alt+Ö öffnet lv als Popup", "Hilfe" in txt or "öffnen" in txt, txt[-160:].replace("\n", " "))
    before = t.focused_pane()
    h.keys("alt+l", wait=0.5)
    t.check("Im Popup greifen herdr-Tasten nicht (Alt+L bleibt bei lv)", t.focused_pane() == before)
    h.keys("esc", wait=1.2)
    h.take(); h.keys("ctrl+b", "f", wait=2.5); txt = h.text_since(0.5)
    t.check("Prefix F öffnet lv als Popup", "Hilfe" in txt or "öffnen" in txt)
    # im Popup in einen Unterordner gehen, Esc: der aufrufende Bereich wechselt mit
    sub = os.path.join(t.work, "unter ordner")
    os.makedirs(sub, exist_ok=True)
    origin = t.focused_pane()
    h.keys("ctrl+r", wait=0.8)
    h.type("unter"); time.sleep(0.6)
    h.keys("enter", wait=1.0)
    h.keys("esc", wait=2.0)
    cwd = t.api("pane", "get", origin).get("pane", {}).get("foreground_cwd")
    t.check("lv-Popup: Esc wechselt den aufrufenden Bereich in den letzten Ordner", cwd == sub, str(cwd))

    # ── Durchgereichte Tasten: bleiben beim Programm ────────────────────────
    target = t.focused_pane()
    h.type(" command cat -v\n"); time.sleep(0.8)
    for spec in ("alt+b", "alt+f", "alt+d", "alt+y", "alt+.", "alt+p", "alt+t", "alt+o", "alt+c",
                 "alt+shift+ö", "alt+m", "alt+n", "alt+i", "alt+u", "alt+x", "alt+q"):
        h.key(spec)
    h.keys("enter", wait=0.6)
    seen = t.pane_text(target)
    line = next((l for l in seen.splitlines()[::-1] if "^[" in l), "")
    for ch in "bfdy.ptocmniuxq":
        t.check(f"Alt+{ch.upper()} geht ans Programm", f"^[{ch}" in line, line[-120:])
    t.check("Alt+Umschalt+Ö geht ans Programm (Bash: lv im Git-Wurzelordner)", "^[M-CM-^V" in line, line[-120:])
    h.take()
    os.write(h.fd, b"\x1b[98;5u"); time.sleep(0.15); os.write(h.fd, b"\x1b[98;5u"); time.sleep(0.5)
    h.keys("enter", wait=0.5)
    t.check("Strg+B zweimal = Strg+B ans Programm", "^B" in t.pane_text(target))
    h.keys("ctrl+c", wait=0.4)
    # Alt+Rück: ohne Zeilenmodus, sonst schluckt das Terminal die Rücktaste selbst
    h.type(" stty -icanon; command cat -v; stty sane\n"); time.sleep(0.8)
    h.keys("alt+backspace", wait=0.6)
    seen = t.pane_text(target)
    t.check("Alt+Rück geht ans Programm", "^[^?" in seen or "^[^H" in seen, seen[-80:].replace("\n", " "))
    h.keys("ctrl+c", wait=0.5)

    # ── Schließen nur über den Prefix ───────────────────────────────────────
    n = len(t.panes())
    h.keys("alt+x", wait=0.5)
    t.check("Alt+X schließt NICHT", len(t.panes()) == n)
    h.keys("ctrl+c", wait=0.3)
    h.keys("ctrl+b", "x", wait=0.9)
    t.check("Prefix X schließt den Bereich", len(t.panes()) == n - 1, f"{n} -> {len(t.panes())}")


def main():
    t = Test()
    try:
        run(t)
    except Exception as exc:  # noqa: BLE001
        import traceback
        traceback.print_exc()
        t.check(f"Abbruch: {exc}", False)
    finally:
        t.stop()
    ok = sum(1 for _, r in t.results if r)
    print(f"\n{ok}/{len(t.results)} OK")
    sys.exit(0 if ok == len(t.results) else 1)


if __name__ == "__main__":
    main()
