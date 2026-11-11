-- Formatierung mit conform.nvim, automatisch beim Speichern.
-- Abschalten: <leader>uf (global) oder :FormatToggle! (nur dieser Buffer).
return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = { "ConformInfo", "FormatToggle" },
  keys = {
    {
      "<leader>lf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = { "n", "x" },
      desc = "Formatieren",
    },
    { "<leader>uf", "<cmd>FormatToggle<CR>", desc = "Formatieren beim Speichern an/aus" },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      python = { "ruff_format" },
    },
    formatters = {
      -- 2 Leerzeichen, case-Zweige einrücken (wie in den eigenen Skripten)
      shfmt = { prepend_args = { "-i", "2", "-ci" } },
    },
    -- Beim Speichern nur die obigen Formatierer, keine LSP-Formatierung (z. B. YAML bleibt unberührt)
    format_on_save = function(buf)
      if vim.g.autoformat == false or vim.b[buf].autoformat == false then
        return
      end
      return { timeout_ms = 1000, lsp_format = "never" }
    end,
  },
  config = function(_, opts)
    require("conform").setup(opts)
    vim.api.nvim_create_user_command("FormatToggle", function(o)
      local scope = o.bang and vim.b or vim.g
      scope.autoformat = scope.autoformat == false
      vim.notify(
        ("Formatieren beim Speichern %s%s"):format(scope.autoformat and "an" or "aus", o.bang and " (Buffer)" or ""),
        vim.log.levels.INFO
      )
    end, { bang = true, desc = "Formatieren beim Speichern an/aus (! = nur Buffer)" })
  end,
  init = function()
    -- gq formatiert über conform
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
