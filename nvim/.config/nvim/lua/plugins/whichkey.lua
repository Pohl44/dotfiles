-- which-key zeigt nach einer Präfix-Taste die möglichen Fortsetzungen
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    spec = {
      { "<leader>b", group = "Buffer" },
      { "<leader>f", group = "Finden" },
      { "<leader>g", group = "Git" },
      { "<leader>l", group = "LSP/Code" },
      { "<leader>u", group = "Schalter" },
      { "[", group = "Vorheriges" },
      { "]", group = "Nächstes" },
      { "g", group = "Gehe zu" },
      { "gr", group = "LSP (Standard)" },
      { "s", group = "Umschließen (Surround)", mode = { "n", "x" } },
      { "z", group = "Falten/Ansicht" },
      { "<C-w>", group = "Fenster" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Tastenkombinationen dieses Buffers",
    },
  },
}
