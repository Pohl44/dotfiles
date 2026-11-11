-- Syntax-Highlighting und Einrückung mit Treesitter.
-- nvim-treesitter (Branch main) installiert nur noch Parser und Queries;
-- dafür braucht es die tree-sitter-CLI und einen C-Compiler.
-- Fehlende Parser werden beim Start im Hintergrund nachinstalliert.
-- stylua: ignore
local parsers = {
  "bash", "lua", "luadoc", "python", "yaml", "json", "toml",
  "markdown", "markdown_inline", "vim", "vimdoc", "query",
  "dockerfile", "gitcommit", "git_config", "gitignore", "git_rebase", "diff",
  "regex", "html", "css", "javascript", "helm",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- unterstützt kein Lazy-Loading
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")
    local installed = ts.get_installed()
    local missing = vim.tbl_filter(function(p)
      return not vim.list_contains(installed, p)
    end, parsers)
    if #missing > 0 then
      ts.install(missing)
    end

    -- Highlighting und Einrückung je Dateityp einschalten, sofern ein Parser existiert
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("config_treesitter", { clear = true }),
      callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if not lang or not pcall(vim.treesitter.start, ev.buf, lang) then
          return
        end
        if vim.treesitter.query.get(lang, "indents") then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
