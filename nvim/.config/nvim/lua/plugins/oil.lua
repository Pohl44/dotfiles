-- Dateibrowser oil.nvim: Ordner als Buffer bearbeiten (umbenennen = Zeile ändern,
-- löschen = Zeile löschen, dann :w). Ersetzt netrw, auch bei `nvim .`.
return {
  "stevearc/oil.nvim",
  lazy = false, -- nötig, damit `nvim <ordner>` direkt oil öffnet
  keys = {
    { "-", "<cmd>Oil<CR>", desc = "Ordner der Datei öffnen (oil)" },
  },
  opts = {
    default_file_explorer = true,
    columns = { "icon" },
    delete_to_trash = true, -- in den Papierkorb statt endgültig löschen
    view_options = { show_hidden = true },
    keymaps = {
      -- Strg+h/l bleiben für den Fensterwechsel frei
      ["<C-h>"] = false,
      ["<C-l>"] = false,
      ["<C-x>"] = { "actions.select", opts = { horizontal = true }, desc = "Im horizontalen Split öffnen" },
      ["gR"] = { "actions.refresh", desc = "Neu laden" },
      ["q"] = { "actions.close", desc = "oil schließen" },
    },
  },
}
