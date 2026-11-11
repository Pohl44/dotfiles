-- mini.nvim: mehrere kleine Module aus einem Plugin
--   mini.icons       Datei-Icons (Nerd Font)
--   mini.statusline  Statuszeile (Modus, Git, Diagnosen, Datei, Position)
--   mini.surround    Klammern/Anführungszeichen: sa (hinzufügen), sd (löschen), sr (ersetzen)
--   mini.pairs       schließende Klammern automatisch einfügen
return {
  "nvim-mini/mini.nvim",
  version = false,
  lazy = false,
  config = function()
    local icons = require("mini.icons")
    icons.setup()
    icons.mock_nvim_web_devicons() -- für Plugins, die nvim-web-devicons erwarten
    require("mini.statusline").setup({ use_icons = true })
    require("mini.surround").setup()
    require("mini.pairs").setup()
    -- s allein ersetzt kein Zeichen mehr (dafür cl), damit sa/sd/sr ohne Wartezeit greifen
    vim.keymap.set({ "n", "x" }, "s", "<Nop>")
  end,
}
