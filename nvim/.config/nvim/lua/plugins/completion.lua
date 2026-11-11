-- Vervollständigung mit blink.cmp: LSP, Pfade, Buffer-Wörter, Snippets.
-- Enter übernimmt (nur wenn ein Eintrag gewählt ist), Strg+N/P oder Pfeile wählen,
-- Strg+Leertaste öffnet das Menü/Doku, Tab/Umschalt+Tab springt in Snippets.
return {
  "saghen/blink.cmp",
  version = "1.*", -- Release-Tags: vorkompilierter Rust-Fuzzy-Matcher
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = { "rafamadriz/friendly-snippets" },
  opts = {
    keymap = { preset = "enter" },
    appearance = { nerd_font_variant = "mono" },
    completion = {
      list = { selection = { preselect = false, auto_insert = true } },
      documentation = { auto_show = true, auto_show_delay_ms = 300 },
    },
    signature = { enabled = true },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
