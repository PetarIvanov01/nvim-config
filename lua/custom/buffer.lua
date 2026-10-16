-- Deleting a buffer should not take its window with it.
--
-- `:bdelete` closes every window showing the buffer when no other listed buffer
-- is left to put there, so with the terminal panel open the editor window above
-- it disappears and the 12-line panel stretches over the whole screen. Here the
-- windows are pointed at something else first -- the buffer they held before,
-- the next listed buffer, or a fresh empty one -- and the buffer goes only
-- afterwards, so the layout that was on screen stays on screen.

local M = {}

---The listed buffer after `buf`, wrapping, or nil when `buf` is the only one.
---@param buf integer
---@return integer?
local function next_listed(buf)
  local listed = {}

  for _, candidate in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[candidate].buflisted then table.insert(listed, candidate) end
  end

  if #listed < 2 then return nil end

  for i, candidate in ipairs(listed) do
    if candidate == buf then return listed[i % #listed + 1] end
  end

  return listed[1]
end

---What `win` should show in place of `buf`: the buffer it was on before, falling
---back to the next one in the buffer list.
---@param win integer
---@param buf integer
---@return integer?
local function replacement(win, buf)
  local alt = vim.api.nvim_win_call(win, function() return vim.fn.bufnr '#' end)

  if alt ~= -1 and alt ~= buf and vim.api.nvim_buf_is_valid(alt) and vim.bo[alt].buflisted then return alt end

  return next_listed(buf)
end

---Delete `buf`, leaving the windows that show it open.
---@param buf? integer the current buffer when omitted
---@return boolean deleted
---@return string? reason why it was left alone
function M.remove(buf)
  if not buf or buf == 0 then buf = vim.api.nvim_get_current_buf() end

  if not vim.api.nvim_buf_is_valid(buf) then return true end
  if vim.bo[buf].modified then return false, 'buffer has unsaved changes' end

  -- Deleting a running terminal would error; `<leader>tc` is the key that knows
  -- how to retire one and leave the panel behind.
  if vim.bo[buf].buftype == 'terminal' then return false, 'use <leader>tc to close a terminal' end

  -- Closing the last file leaves an empty buffer behind, the way `:enew` does.
  -- One for all the orphaned windows rather than one each: several windows on
  -- the same file would otherwise each get their own no-name buffer.
  local empty

  -- Every tab page, not just this one: a window elsewhere showing the buffer
  -- would be closed by the delete just the same.
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      local target = replacement(win, buf)

      if not target then
        empty = empty or vim.api.nvim_create_buf(true, false)
        target = empty
      end

      vim.api.nvim_win_set_buf(win, target)
    end
  end

  vim.api.nvim_buf_delete(buf, {})

  return true
end

return M
