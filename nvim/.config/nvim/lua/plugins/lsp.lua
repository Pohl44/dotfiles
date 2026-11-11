-- LSP über die eingebaute API (vim.lsp.config / vim.lsp.enable).
-- Die Server kommen aus mise (kein mason); nvim-lspconfig liefert nur die
-- Standard-Configs (cmd, filetypes, root_markers) im Ordner lsp/.
-- stylua: ignore
local servers = {
  "lua_ls", "bashls", "yamlls", "jsonls", "pyright", "ruff",
  "marksman", "taplo", "html", "cssls",
}

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "b0o/SchemaStore.nvim" }, -- JSON-Schemas (package.json, tsconfig …)
  config = function()
    -- Für alle Server: Fähigkeiten von blink.cmp (Vervollständigung, Snippets)
    vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

    -- Lua: Neovim-Runtime und vim-Global bekannt machen
    -- Ohne Projekt-Root liefert lua_ls keine Diagnosen; dann den Ordner der Datei nehmen.
    local lua_markers = vim.lsp.config.lua_ls.root_markers or { ".git" }
    vim.lsp.config("lua_ls", {
      root_dir = function(buf, on_dir)
        on_dir(vim.fs.root(buf, lua_markers) or vim.fs.dirname(vim.api.nvim_buf_get_name(buf)))
      end,
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = { globals = { "vim" } },
          workspace = {
            checkThirdParty = false,
            library = { vim.env.VIMRUNTIME, "${3rd}/luv/library" },
          },
          hint = { enable = true },
          telemetry = { enable = false },
        },
      },
    })

    -- YAML: Schemas automatisch aus dem SchemaStore (online, ohne Zusatzinstallation)
    -- und Kubernetes für typische Manifest-Pfade. Einzelne Datei: Kopfzeile
    -- `# yaml-language-server: $schema=kubernetes`
    vim.lsp.config("yamlls", {
      -- nur "yaml": die Default-Liste enthält Dateitypen, die Neovim nicht kennt (Health-Warnung)
      filetypes = { "yaml" },
      settings = {
        redhat = { telemetry = { enabled = false } },
        yaml = {
          schemaStore = { enable = true, url = "https://www.schemastore.org/api/json/catalog.json" },
          schemas = {
            kubernetes = {
              "**/k8s/**/*.yaml",
              "**/kubernetes/**/*.yaml",
              "**/manifests/**/*.yaml",
              "*.k8s.yaml",
            },
          },
          validate = true,
          keyOrdering = false,
        },
      },
    })

    -- JSON: Schemas aus SchemaStore.nvim (erst beim Serverstart geladen, spart Startzeit)
    vim.lsp.config("jsonls", {
      settings = { json = { validate = { enable = true } } },
      before_init = function(_, config)
        config.settings.json.schemas = require("schemastore").json.schemas()
      end,
    })

    -- Markdown: ohne den unbekannten Dateityp "markdown.mdx"
    vim.lsp.config("marksman", { filetypes = { "markdown" } })

    -- Python: pyright für Typen, ruff für Linting/Imports
    vim.lsp.config("pyright", {
      settings = { pyright = { disableOrganizeImports = true } },
    })

    vim.lsp.enable(servers)

    -- Tastenkombinationen, sobald ein Server an einem Buffer hängt.
    -- Neovim-Standards bleiben: K Hover, grn/gra/grr/gri Umbenennen/Aktion/Referenzen/Implementierung,
    -- [d / ]d Diagnosen, Strg+S Signatur im Einfügemodus.
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("config_lsp", { clear = true }),
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        -- Hover übernimmt pyright, nicht ruff
        if client and client.name == "ruff" then
          client.server_capabilities.hoverProvider = false
        end

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
        end
        local fzf = function(cmd)
          return function()
            require("fzf-lua")[cmd]()
          end
        end
        map("n", "gd", vim.lsp.buf.definition, "Gehe zu Definition")
        map("n", "gD", vim.lsp.buf.declaration, "Gehe zu Deklaration")
        map("n", "K", vim.lsp.buf.hover, "Hover-Dokumentation")
        map("n", "<leader>lr", vim.lsp.buf.rename, "Umbenennen")
        map({ "n", "x" }, "<leader>la", vim.lsp.buf.code_action, "Code-Aktion")
        map("n", "<leader>lR", fzf("lsp_references"), "Referenzen")
        map("n", "<leader>li", fzf("lsp_implementations"), "Implementierungen")
        map("n", "<leader>lt", fzf("lsp_typedefs"), "Typdefinition")
        map("n", "<leader>ls", fzf("lsp_document_symbols"), "Symbole der Datei")
        map("n", "<leader>lS", fzf("lsp_live_workspace_symbols"), "Symbole im Projekt")
        map("n", "<leader>lI", "<cmd>checkhealth vim.lsp<CR>", "LSP-Status")
      end,
    })
  end,
}
