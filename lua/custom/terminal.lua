local M = {}

local shells = {
  bash = 'C:/Users/petar.iva/AppData/Local/Programs/Git/bin/bash.exe',
  cmd = 'cmd.exe',
  powershell = 'powershell.exe',
}

local shell = shells.bash

local current = nil

-- Return all terminal buffers created by this module.
local function terminals()
  local result = {}

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].custom_terminal then table.insert(result, buf) end
  end

  return result
end

-- Find the window currently showing one of our terminals.
local function terminal_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)

    if vim.b[buf].custom_terminal then return win end
  end

  return nil
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

  vim.cmd 'startinsert'
end

function M.new()
  local win = terminal_window()

  if not win then win = open_window() end

  vim.api.nvim_set_current_win(win)

  vim.cmd 'enew'

  local command

  if shell == shells.bash then
    command = { shell, '--login', '-i' }
  else
    command = { shell }
  end

  local job_id = vim.fn.jobstart(command, {
    term = true,
  })

  if job_id <= 0 then
    vim.notify('Failed to start terminal', vim.log.levels.ERROR)
    return
  end

  local buf = vim.api.nvim_get_current_buf()

  -- Keep terminal alive when its window is hidden
  vim.bo[buf].bufhidden = 'hide'

  -- Mark this buffer as one of our custom terminals
  vim.b[buf].custom_terminal = true

  current = buf

  vim.cmd 'startinsert'
end

function M.toggle()
  local list = terminals()

  -- No terminal yet -> create the first one
  if #list == 0 then
    M.new()
    return
  end

  local win = terminal_window()

  -- Visible -> hide
  if win then
    vim.api.nvim_win_hide(win)
    return
  end

  -- Hidden -> show current terminal again
  if not current or not vim.api.nvim_buf_is_valid(current) then current = list[1] end

  show(current)
end

function M.next()
  local list = terminals()

  if #list == 0 then
    M.new()
    return
  end

  local index = 1

  for i, buf in ipairs(list) do
    if buf == current then
      index = i
      break
    end
  end

  index = index % #list + 1

  show(list[index])
end

function M.prev()
  local list = terminals()

  if #list == 0 then
    M.new()
    return
  end

  local index = 1

  for i, buf in ipairs(list) do
    if buf == current then
      index = i
      break
    end
  end

  index = (index - 2) % #list + 1

  show(list[index])
end

function M.close()
  local list = terminals()

  if #list <= 1 then
    vim.notify('Cannot close the last terminal', vim.log.levels.INFO)
    return
  end

  local buf = current

  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end

  local next_buf

  for i, terminal_buf in ipairs(list) do
    if terminal_buf == buf then
      next_buf = list[i + 1] or list[i - 1]
      break
    end
  end

  vim.api.nvim_buf_delete(buf, { force = true })

  current = next_buf

  if next_buf then show(next_buf) end
end

return M
