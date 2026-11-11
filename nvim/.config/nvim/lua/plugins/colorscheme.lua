-- Farbschema tokyonight, Variante "night" (= kitty-Theme „Tokyo Night“)
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000, -- vor allen anderen Plugins laden
  opts = { style = "night" },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight-night")
  end,
}
