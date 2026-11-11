-- Grundeinstellungen
local opt = vim.opt

-- Zeilennummern: absolut für die aktuelle Zeile, sonst relativ
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes" -- Platz für Git-/Diagnose-Zeichen immer reservieren
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.breakindent = true
opt.showmode = false -- Modus steht in der Statuszeile
opt.laststatus = 2
opt.winborder = "rounded" -- Rahmen für Hover/Signatur-Fenster
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars = { eob = " " }
opt.mouse = "a"
opt.confirm = true -- bei ungespeicherten Änderungen nachfragen statt Fehler
opt.termguicolors = true

-- Fenster
opt.splitright = true
opt.splitbelow = true

-- Suche: ohne Groß-/Kleinschreibung, außer der Suchbegriff enthält Großbuchstaben
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split" -- Vorschau für :s

-- Einrückung (Python-ftplugin setzt selbst 4 Leerzeichen)
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

-- Persistentes Undo (in ~/.local/state/nvim/undo), keine Swap-Dateien
opt.undofile = true
opt.swapfile = false

opt.updatetime = 250 -- schnellere CursorHold-Events (gitsigns, LSP)
opt.timeoutlen = 400 -- which-key erscheint schneller
opt.shortmess:append("I") -- kein Intro-Bildschirm

-- Nicht genutzte Provider abschalten (schnellerer Start, keine Health-Warnungen)
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- Zwischenablage ------------------------------------------------------------
-- Alle Yanks/Pastes laufen über die Systemzwischenablage ("+).
-- Mit xclip/xsel (X11) bzw. wl-copy (Wayland) nutzt Neovim seinen normalen Provider.
-- Fehlen diese Tools, wird OSC 52 verwendet: kitty übernimmt Kopiertes in die
-- Systemzwischenablage (auch über SSH). Einfügen liest NICHT aus dem Terminal
-- (kitty würde jedes Mal nachfragen), sondern liefert das zuletzt in Neovim
-- Kopierte. Fremdes aus der Zwischenablage dann mit Strg+Umschalt+V einfügen.
local function has_native_clipboard()
  if vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-copy") == 1 then
    return true
  end
  return vim.env.DISPLAY ~= nil and (vim.fn.executable("xclip") == 1 or vim.fn.executable("xsel") == 1)
end

if not has_native_clipboard() then
  local osc52 = require("vim.ui.clipboard.osc52")
  local cache = {} -- zuletzt kopierter Inhalt je Register
  local function copy(reg)
    local send = osc52.copy(reg)
    return function(lines, regtype)
      cache[reg] = { lines, regtype }
      send(lines)
    end
  end
  local function paste(reg)
    return function()
      return cache[reg] or { {}, "v" }
    end
  end
  vim.g.clipboard = {
    name = "OSC 52 (Fallback ohne xclip)",
    copy = { ["+"] = copy("+"), ["*"] = copy("*") },
    paste = { ["+"] = paste("+"), ["*"] = paste("*") },
  }
end

-- Verzögert setzen: das Laden des Providers bremst sonst den Start.
vim.schedule(function()
  opt.clipboard = "unnamedplus"
end)

-- Diagnosen (LSP)
vim.diagnostic.config({
  severity_sort = true,
  virtual_text = { spacing = 2, source = "if_many" },
  float = { source = "if_many" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
  },
})
