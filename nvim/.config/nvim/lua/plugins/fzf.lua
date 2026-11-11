-- Fuzzy-Suche mit fzf-lua (nutzt fd, rg, bat und fzf aus mise)
local function fzf(cmd, opts)
  return function()
    require("fzf-lua")[cmd](opts)
  end
end

return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  keys = {
    { "<leader><leader>", fzf("files"), desc = "Dateien" },
    { "<leader>ff", fzf("files"), desc = "Dateien" },
    { "<leader>fg", fzf("live_grep"), desc = "Text suchen (rg)" },
    { "<leader>fw", fzf("grep_cword"), desc = "Wort unter Cursor suchen" },
    { "<leader>fw", fzf("grep_visual"), mode = "x", desc = "Auswahl suchen" },
    { "<leader>fb", fzf("buffers"), desc = "Buffer" },
    { "<leader>fr", fzf("oldfiles"), desc = "Zuletzt geöffnet" },
    { "<leader>fh", fzf("helptags"), desc = "Hilfe" },
    { "<leader>fk", fzf("keymaps"), desc = "Tastenkombinationen" },
    { "<leader>fd", fzf("diagnostics_document"), desc = "Diagnosen (Datei)" },
    { "<leader>fD", fzf("diagnostics_workspace"), desc = "Diagnosen (alle)" },
    { "<leader>f/", fzf("blines"), desc = "Zeilen im Buffer" },
    { "<leader>fc", fzf("commands"), desc = "Befehle" },
    { "<leader>f.", fzf("resume"), desc = "Letzte Suche fortsetzen" },
    { "<leader>fn", fzf("files", { cwd = vim.fn.stdpath("config") }), desc = "Neovim-Config" },
    { "<leader>gc", fzf("git_commits"), desc = "Commits" },
    { "<leader>gC", fzf("git_bcommits"), desc = "Commits dieser Datei" },
    { "<leader>gf", fzf("git_status"), desc = "Geänderte Dateien" },
  },
  init = function()
    -- vim.ui.select (z. B. Code-Aktionen) über fzf-lua; lädt das Plugin erst bei Bedarf
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.ui.select = function(...)
      require("fzf-lua").register_ui_select()
      return vim.ui.select(...)
    end
  end,
  opts = {
    fzf_colors = true, -- Farben vom Farbschema übernehmen
    winopts = { height = 0.85, width = 0.85, preview = { layout = "flex" } },
    oldfiles = { include_current_session = true },
  },
}
