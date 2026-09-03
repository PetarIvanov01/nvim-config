local M = {}

M.default = 'tokyonight-night'

-- Stored outside the config repo so switching themes never touches git status.
M.path = vim.fn.stdpath 'data' .. '/theme.txt'

function M.load()
  local file = io.open(M.path, 'r')
  if not file then return M.default end

  local name = file:read '*l'
  file:close()

  return (name and name ~= '') and name or M.default
end

function M.save(name)
  local file = io.open(M.path, 'w')
  if not file then return end

  file:write(name)
  file:close()
end

return M
