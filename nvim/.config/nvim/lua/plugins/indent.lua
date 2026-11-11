-- Einrückungslinien, der aktuelle Block wird hervorgehoben
return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    indent = { char = "│" },
    scope = { show_start = false, show_end = false },
    exclude = { filetypes = { "help", "oil", "lazy", "checkhealth", "man", "markdown" } },
  },
}
