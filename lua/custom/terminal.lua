local M = {}

local shell = require 'config.shell'

local current = nil

-- Buffers that were on screen when the panel was last hidden, left to right.
-- Toggling back brings the same panes up in the same order.
local last_layout = {}

-- Return all terminal buffers created by this module.
local function terminals()
  local result = {}

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].custom_terminal then table.insert(result, buf) end
  end

  return result
end

-- Every window currently showing one of our terminals.
local function terminal_windows()
  local result = {}

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)

    if vim.b[buf].custom_terminal then table.insert(result, win) end
  end

  return result
end

-- The terminal window a command should act on: the focused one when a terminal
-- has focus, otherwise the leftmost pane on screen.
local function terminal_window()
  local win = vim.api.nvim_get_current_win()

  if vim.b[vim.api.nvim_win_get_buf(win)].custom_terminal then return win end

  return terminal_windows()[1]
end

-- The terminal a command should act on: whatever sits in the acting window,
-- falling back to the last one shown while the panel is hidden.
local function active_buf()
  local win = terminal_window()

  if win then return vim.api.nvim_win_get_buf(win) end

  return current
end

-- Terminals visible in a pane other than the acting one, so cycling never puts
-- the same terminal on screen twice.
local function shown_elsewhere()
  local set = {}
  local acting = terminal_window()

  for _, win in ipairs(terminal_windows()) do
    if win ~= acting then set[vim.api.nvim_win_get_buf(win)] = true end
  end

  return set
end

local function open_window()
  vim.cmd 'botright 12split'
  return vim.api.nvim_get_current_win()
end

local function show(buf)
  local win = terminal_window()

  if not win then win = open_window() end

  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_set_current_win(win)

  current = buf

  -- Open managed terminals in Terminal-Normal mode so terminal and window
  -- navigation mappings are immediately available. Press `i` to type.
  vim.cmd 'stopinsert'
end

-- Start a shell in `win`, replacing whatever it holds.
local function spawn(win)
  vim.api.nvim_set_current_win(win)

  vim.cmd 'enew'

  local job_id = vim.fn.jobstart(shell.terminal_command(), {
    term = true,
  })

  if job_id <= 0 then
    vim.notify('Failed to start terminal', vim.log.levels.ERROR)
    return
  end

  local buf = vim.api.nvim_get_current_buf()

  -- Keep terminal alive when its window is hidden
  vim.bo[buf].bufhidden = 'hide'

  -- `:enew` above creates an ordinary listed buffer and `jobstart` converts it
  -- in place, so without this the terminal stays in the `:buffers` list and
  -- `:bnext`/`:bprevious` cycle onto it. Terminal navigation here does not rely
  -- on the listed state -- `terminals()` scans `nvim_list_bufs()` for the
  -- `custom_terminal` flag -- so unlisting costs nothing.
  vim.bo[buf].buflisted = false

  -- Mark this buffer as one of our custom terminals
  vim.b[buf].custom_terminal = true

  current = buf

  vim.cmd 'stopinsert'
end

function M.new()
  local win = terminal_window()

  if not win then win = open_window() end

  spawn(win)
end

-- Open a terminal beside the current one instead of replacing it.
function M.vnew()
  local win = terminal_window()

  -- Nothing on screen yet -> the first terminal is the panel itself
  if not win then
    spawn(open_window())
    return
  end

  vim.api.nvim_set_current_win(win)

  vim.cmd 'rightbelow vsplit'

  spawn(vim.api.nvim_get_current_win())
end

-- Bring the remembered panes back, side by side.
local function restore(list)
  local bufs = {}

  for _, buf in ipairs(last_layout) do
    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].custom_terminal then table.insert(bufs, buf) end
  end

  if #bufs == 0 then
    local buf = current

    if not buf or not vim.api.nvim_buf_is_valid(buf) then buf = list[1] end

    bufs = { buf }
  end

  local win = open_window()

  vim.api.nvim_win_set_buf(win, bufs[1])

  for i = 2, #bufs do
    vim.cmd 'rightbelow vsplit'
    vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), bufs[i])
  end

  show(current and vim.tbl_contains(bufs, current) and current or bufs[1])
end

function M.toggle()
  local list = terminals()

  -- No terminal yet -> create the first one
  if #list == 0 then
    M.new()
    return
  end

  local wins = terminal_windows()

  -- Hidden -> show the same panes again
  if #wins == 0 then
    restore(list)
    return
  end

  -- On screen but the cursor is elsewhere -> step into it rather than hide it.
  -- Hiding a panel you are only looking at costs two keystrokes to get back,
  -- and it is never what the key was pressed for while editing.
  if not vim.b[vim.api.nvim_get_current_buf()].custom_terminal then
    local target = wins[1]

    -- Prefer the pane holding the terminal last worked in, so focus returns
    -- where it left off instead of always to the leftmost pane.
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_get_buf(win) == current then
        target = win
        break
      end
    end

    vim.api.nvim_set_current_win(target)

    return
  end

  -- Focused -> hide every pane, remembering the layout
  last_layout = {}

  for _, win in ipairs(wins) do
    table.insert(last_layout, vim.api.nvim_win_get_buf(win))
  end

  for _, win in ipairs(wins) do
    vim.api.nvim_win_hide(win)
  end
end

-- Walk the terminal list from the pane's current terminal, skipping any that
-- another pane is already showing.
local function cycle(step)
  local list = terminals()

  if #list == 0 then
    M.new()
    return
  end

  local anchor = active_buf()
  local index = 1

  for i, buf in ipairs(list) do
    if buf == anchor then
      index = i
      break
    end
  end

  local busy = shown_elsewhere()

  for _ = 1, #list do
    index = (index - 1 + step) % #list + 1

    if not busy[list[index]] then
      show(list[index])
      return
    end
  end
end

function M.next() cycle(1) end

function M.prev() cycle(-1) end

function M.close()
  local list = terminals()

  if #list <= 1 then
    vim.notify('Cannot close the last terminal', vim.log.levels.INFO)
    return
  end

  local buf = active_buf()

  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end

  local busy = shown_elsewhere()
  local next_buf

  for i, terminal_buf in ipairs(list) do
    if terminal_buf == buf then
      -- Take over a neighbour no other pane is already showing
      local candidates = {}

      if list[i + 1] then table.insert(candidates, list[i + 1]) end
      if list[i - 1] then table.insert(candidates, list[i - 1]) end

      for _, candidate in ipairs(candidates) do
        if not busy[candidate] then
          next_buf = candidate
          break
        end
      end

      break
    end
  end

  -- Grab the pane before the delete: afterwards it no longer holds a terminal,
  -- so `terminal_window()` would hand back a different one.
  local win = terminal_window()

  vim.api.nvim_buf_delete(buf, { force = true })

  current = next_buf

  if not (win and vim.api.nvim_win_is_valid(win)) then
    if next_buf then show(next_buf) end
    return
  end

  if next_buf then
    vim.api.nvim_win_set_buf(win, next_buf)
    vim.api.nvim_set_current_win(win)
    vim.cmd 'stopinsert'
  else
    -- Every remaining terminal is already on screen -> drop the empty pane
    pcall(vim.api.nvim_win_close, win, true)
  end
end

M.float = function(cmd)
  local width = math.floor(vim.o.columns * 0.85)
  local height = math.floor(vim.o.lines * 0.85)

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })

  vim.fn.termopen(cmd, {
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    end,
  })

  vim.cmd 'startinsert'
end

return M
