-- Git-Zeichen in der Randspalte, Hunks und Blame mit gitsigns
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    on_attach = function(buf)
      local gs = require("gitsigns")
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
      end
      local function range()
        return { vim.fn.line("."), vim.fn.line("v") }
      end

      map("n", "]h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, "Nächster Hunk")
      map("n", "[h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, "Vorheriger Hunk")

      map("n", "<leader>gs", gs.stage_hunk, "Hunk stagen/unstagen")
      map("x", "<leader>gs", function()
        gs.stage_hunk(range())
      end, "Auswahl stagen")
      map("n", "<leader>gr", gs.reset_hunk, "Hunk zurücksetzen")
      map("x", "<leader>gr", function()
        gs.reset_hunk(range())
      end, "Auswahl zurücksetzen")
      map("n", "<leader>gS", gs.stage_buffer, "Datei stagen")
      map("n", "<leader>gR", gs.reset_buffer, "Datei zurücksetzen")
      map("n", "<leader>gp", gs.preview_hunk_inline, "Hunk-Vorschau")
      map("n", "<leader>gb", function()
        gs.blame_line({ full = true })
      end, "Blame der Zeile")
      map("n", "<leader>gB", gs.blame, "Blame der Datei")
      map("n", "<leader>gt", gs.toggle_current_line_blame, "Zeilen-Blame an/aus")
      map("n", "<leader>gd", gs.diffthis, "Diff gegen Index")
      map({ "o", "x" }, "ih", gs.select_hunk, "Hunk (Textobjekt)")
    end,
  },
}
