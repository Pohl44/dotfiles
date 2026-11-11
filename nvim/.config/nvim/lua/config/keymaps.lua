-- Allgemeine Tastenkombinationen (Plugin-Keymaps stehen in lua/plugins/*.lua)
local map = vim.keymap.set

-- Esc hebt die Suchmarkierung auf
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Suchmarkierung aufheben" })

-- Fenster mit Strg+h/j/k/l wechseln
map("n", "<C-h>", "<C-w>h", { desc = "Fenster links" })
map("n", "<C-j>", "<C-w>j", { desc = "Fenster unten" })
map("n", "<C-k>", "<C-w>k", { desc = "Fenster oben" })
map("n", "<C-l>", "<C-w>l", { desc = "Fenster rechts" })

-- Terminal-Modus mit doppeltem Esc verlassen
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Terminal-Modus verlassen" })

-- Speichern / Beenden
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Speichern" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Fenster schließen" })
map("n", "<leader>Q", "<cmd>qall<CR>", { desc = "Neovim beenden" })

-- Buffer ([b / ]b sind in Neovim schon belegt)
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Buffer schließen" })
map("n", "<leader>bo", "<cmd>%bdelete|edit#|bdelete#<CR>", { desc = "Andere Buffer schließen" })

-- Einrücken im visuellen Modus, Auswahl bleibt erhalten
map("v", "<", "<gv", { desc = "Ausrücken" })
map("v", ">", ">gv", { desc = "Einrücken" })

-- Einfügen über Auswahl, ohne das Register zu überschreiben
map("x", "<leader>v", '"_dP', { desc = "Einfügen ohne Register zu überschreiben" })

-- Schalter (UI)
map("n", "<leader>uw", "<cmd>set wrap!<CR>", { desc = "Zeilenumbruch an/aus" })
map("n", "<leader>un", "<cmd>set relativenumber!<CR>", { desc = "Relative Nummern an/aus" })
map("n", "<leader>ud", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Diagnosen an/aus" })
map("n", "<leader>uh", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Inlay-Hints an/aus" })

-- Diagnosen
map("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Diagnose der Zeile" })
map("n", "<leader>lq", vim.diagnostic.setloclist, { desc = "Diagnosen in Location-Liste" })
