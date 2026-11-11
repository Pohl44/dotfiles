-- Einstieg der Neovim-Config. Aufbau:
--   lua/config/options.lua   Grundeinstellungen (inkl. Zwischenablage)
--   lua/config/keymaps.lua   allgemeine Tastenkombinationen
--   lua/config/autocmds.lua  Autocommands und Dateitypen
--   lua/config/pin.lua       Datei rechts anheften (:Pin / :Unpin)
--   lua/plugins/*.lua        ein Thema pro Datei, von lazy.nvim geladen

-- Lua-Module byte-kompiliert cachen (schnellerer Start).
vim.loader.enable()

-- Leader muss vor lazy.nvim und allen Keymaps gesetzt sein.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")

-- lazy.nvim bei Bedarf installieren (Bootstrap).
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", repo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "lazy.nvim konnte nicht geklont werden:\n" .. out, "ErrorMsg" } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  -- Lockfile liegt im Config-Ordner (dotfiles) und wird mitversioniert.
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  install = { colorscheme = { "tokyonight" } },
  rocks = { enabled = false }, -- kein Plugin braucht luarocks
  checker = { enabled = false }, -- keine automatische Update-Prüfung
  change_detection = { notify = false },
  ui = { border = "rounded" },
  performance = {
    rtp = {
      -- Ungenutzte Standard-Plugins abschalten (netrw ersetzt oil.nvim).
      disabled_plugins = { "gzip", "netrwPlugin", "tohtml", "tutor" },
    },
  },
})

require("config.keymaps")
require("config.autocmds")
require("config.pin").setup()
