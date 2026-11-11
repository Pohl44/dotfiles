-- Autocommands
local augroup = vim.api.nvim_create_augroup("config", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- Kopierten Text kurz hervorheben
autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

-- Beim Öffnen an die letzte Cursorposition springen (nicht bei Commit-Nachrichten)
autocmd("BufReadPost", {
  group = augroup,
  callback = function(ev)
    local ft = vim.bo[ev.buf].filetype
    if ft == "gitcommit" or ft == "gitrebase" or vim.b[ev.buf].last_pos_done then
      return
    end
    vim.b[ev.buf].last_pos_done = true
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Fenstergrößen angleichen, wenn sich die Terminalgröße ändert
autocmd("VimResized", {
  group = augroup,
  command = "wincmd =",
})

-- Hilfe, Quickfix usw. mit q schließen
autocmd("FileType", {
  group = augroup,
  pattern = { "help", "qf", "checkhealth", "man", "lspinfo" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true, desc = "Schließen" })
  end,
})

-- Dateitypen: Helm-Templates erkennen (templates/*.yaml|tpl in einem Chart)
local function helm_or(fallback)
  return function(path)
    local chart = vim.fs.find("Chart.yaml", { path = vim.fs.dirname(path), upward = true })[1]
    if chart and path:find("/templates/", 1, true) then
      return "helm"
    end
    return fallback
  end
end
vim.filetype.add({
  pattern = {
    [".*/templates/.*%.ya?ml"] = helm_or("yaml"),
    [".*/templates/.*%.tpl"] = helm_or("smarty"),
  },
})
