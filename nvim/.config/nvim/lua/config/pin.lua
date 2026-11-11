-- Datei rechts anheften
-- <leader>p  aktuellen Buffer rechts anheften bzw. Anheftung lösen (Umschalter)
-- <leader>P  angehefteten Split schließen
-- :Pin [datei]  heftet den aktuellen Buffer oder die Datei an (ersetzt eine alte Anheftung)
-- :Unpin        löst die Anheftung (Fenster bleibt), :Unpin! schließt das Fenster
-- Angeheftet heißt: vertikaler Split ganz rechts, feste Breite (winfixwidth) und
-- winfixbuf (in diesem Fenster kann kein anderer Buffer geöffnet werden).
-- Start mit `nvim -O a b` (so ruft lv auf): b steht rechts und wird automatisch
-- angeheftet. Abschalten mit vim.g.pin_on_start = false.
local M = {}

-- Breite des angehefteten Fensters (höchstens die halbe Bildschirmbreite)
local function pin_width()
  return math.min(vim.g.pin_width or 80, math.floor(vim.o.columns / 2))
end

local function set_local(win, name, value)
  vim.api.nvim_set_option_value(name, value, { scope = "local", win = win })
end

-- Angeheftetes Fenster im aktuellen Tab suchen
function M.find()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.w[win].pinned then
      return win
    end
  end
end

-- Ein vorhandenes Fenster zum angehefteten machen
local function apply(win)
  vim.w[win].pinned = true
  set_local(win, "winfixbuf", true)
  set_local(win, "winfixwidth", true)
  set_local(win, "winbar", " 󰐃 angeheftet: %t%m")
  vim.api.nvim_win_set_width(win, pin_width())
end

-- Anheftung lösen; mit close = true das Fenster schließen
function M.unpin(close)
  local win = M.find()
  if not win then
    vim.notify("Keine Datei angeheftet", vim.log.levels.INFO)
    return
  end
  if close and #vim.api.nvim_tabpage_list_wins(0) > 1 then
    vim.api.nvim_win_close(win, false)
  else
    vim.w[win].pinned = nil
    set_local(win, "winfixbuf", false)
    set_local(win, "winfixwidth", false)
    set_local(win, "winbar", "")
  end
  vim.cmd("wincmd =")
end

-- Aktuellen Buffer (oder file) rechts anheften, Fokus bleibt im aktuellen Fenster
function M.pin(file)
  local old = M.find()
  if old then
    -- es gibt nur eine Anheftung pro Tab
    local was_current = old == vim.api.nvim_get_current_win()
    M.unpin(#vim.api.nvim_tabpage_list_wins(0) > 1)
    if was_current then
      vim.cmd("wincmd p")
    end
  end
  local cur = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  vim.cmd("botright vsplit")
  local win = vim.api.nvim_get_current_win()
  if file and file ~= "" then
    vim.cmd.edit(vim.fn.fnameescape(file))
  else
    vim.api.nvim_win_set_buf(win, buf)
  end
  apply(win)
  if vim.api.nvim_win_is_valid(cur) then
    vim.api.nvim_set_current_win(cur)
  end
end

function M.toggle()
  if M.find() then
    M.unpin(false)
  else
    M.pin()
  end
end

function M.setup()
  vim.api.nvim_create_user_command("Pin", function(o)
    M.pin(o.args)
  end, { nargs = "?", complete = "file", desc = "Datei rechts anheften" })
  vim.api.nvim_create_user_command("Unpin", function(o)
    M.unpin(o.bang)
  end, { bang = true, desc = "Anheftung lösen (! schließt das Fenster)" })

  vim.keymap.set("n", "<leader>p", M.toggle, { desc = "Datei rechts anheften/lösen" })
  vim.keymap.set("n", "<leader>P", function()
    M.unpin(true)
  end, { desc = "Angehefteten Split schließen" })

  -- `nvim -O a b`: rechtes Fenster (b) automatisch anheften
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("config_pin", { clear = true }),
    callback = function()
      if vim.g.pin_on_start == false or vim.fn.argc() ~= 2 then
        return
      end
      local vertical = vim.iter(vim.v.argv):any(function(a)
        return a:match("^%-O%d*$") ~= nil
      end)
      local wins = vim.api.nvim_tabpage_list_wins(0)
      if vertical and #wins == 2 then
        apply(wins[2])
        vim.api.nvim_set_current_win(wins[1])
      end
    end,
  })
end

return M
