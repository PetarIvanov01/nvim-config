-- lazygit in a floating terminal, wired so that picking a file in it opens
-- that file in this Neovim.
--
-- Out of the box neither of lazygit's file keys does that: `o` runs `os.open`,
-- which on Windows is `start "" {{filename}}` and hands the file to whatever
-- application the extension is associated with, and `e` runs `os.edit`, which
-- with no $EDITOR set opens some other editor -- or a second Neovim nested
-- inside the float. Both leave the buffer you wanted somewhere other than here.
--
-- lazygit ships an `editPreset: nvim-remote` for exactly this, but its template
-- is POSIX shell (`[ -z "$NVIM" ] && ... || ...`) and lazygit runs os commands
-- through `cmd /c` on Windows, where that line is nonsense. So we write our own
-- config instead, with this instance's RPC address baked in, and point lazygit
-- at it through LG_CONFIG_FILE.
--
-- The detour through a .cmd shim is lazygit's quoting: it substitutes
-- {{filename}} already wrapped in double quotes, and the path has to end up
-- *inside* the double-quoted key sequence passed to `--remote-send`. `%~2` is
-- cmd's only way to strip one pair of quotes before re-wrapping.

local M = {}

local terminal = require 'custom.terminal'

-- The float, and the window it was opened from, while lazygit is running.
local state = {}

local function cache_path(name) return vim.fs.joinpath(vim.fn.stdpath 'cache', name) end

local shim = cache_path 'lazygit-open.cmd'
local config = cache_path 'lazygit.yml'

---The address other processes can reach this Neovim on.
---@return string
local function address()
  if vim.v.servername ~= '' then return vim.v.servername end

  return vim.fn.serverstart()
end

---Write the shim and the config lazygit runs with. Both are cheap and the
---address changes with every Neovim, so they are rewritten on every open.
---@param addr string
local function write_files(addr)
  local nvim = vim.v.progpath

  -- `\r` plus binary mode so the batch file ends up with the CRLF line endings
  -- cmd expects. `%~1` is the address, `%~2` the file, `%~3` an optional line.
  vim.fn.writefile({
    '@echo off\r',
    ('"%s" --server %%~1 --remote-send "<C-\\><C-N>:LazygitOpen %%~2<CR>"\r'):format(nvim),
    ('if not "%%~3"=="" "%s" --server %%~1 --remote-send ":%%~3<CR>"\r'):format(nvim),
  }, shim, 'b')

  ---One `os` entry: the shim, this Neovim's address, and what lazygit substitutes into it.
  local function run(key, args) return ("  %s: '\"%s\" \"%s\" %s'"):format(key, shim, addr, args) end

  vim.fn.writefile({
    '# Written by lua/custom/lazygit.lua on every <leader>gg -- edits here are lost.',
    'os:',
    run('open', '{{filename}}'),
    run('edit', '{{filename}}'),
    run('editAtLine', '{{filename}} {{line}}'),
    run('openDirInEditor', '{{dir}}'),
    -- The shim returns immediately, so lazygit has no reason to suspend itself
    -- and hand the terminal over the way it would for a real editor.
    '  editInTerminal: false',
    -- lazygit waits on this one (commit messages, the rebase todo list), so it
    -- does need an editor that blocks: a nested Neovim inside the float.
    ("  editAtLineAndWait: '\"%s\" -- {{filename}} +{{line}}'"):format(nvim),
  }, config)
end

---lazygit merges a comma-separated list, so the personal config still applies.
---An empty file is skipped: lazygit rejects one listed explicitly.
---@param addr string
---@return string
local function config_files(addr)
  write_files(addr)

  local files = {}
  local user = vim.fs.joinpath(vim.env.LOCALAPPDATA or '', 'lazygit', 'config.yml')

  if vim.fn.getfsize(user) > 0 then table.insert(files, user) end

  table.insert(files, config)

  return table.concat(files, ',')
end

-- Take the float down. Deleting the terminal buffer stops lazygit with it, so
-- picking a file never leaves the process behind.
local function close()
  local win, buf = state.win, state.buf

  state = {}

  if win and vim.api.nvim_win_is_valid(win) then pcall(vim.api.nvim_win_close, win, true) end
  if buf and vim.api.nvim_buf_is_valid(buf) then pcall(vim.api.nvim_buf_delete, buf, { force = true }) end
end

-- Where a file picked in lazygit should land: the window <leader>gg was pressed
-- in, or any other window holding an ordinary buffer if that one is gone.
local function target_window(origin)
  if origin and vim.api.nvim_win_is_valid(origin) and vim.bo[vim.api.nvim_win_get_buf(origin)].buftype == '' then return origin end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= state.win and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == '' then return win end
  end
end

---Open `path` here, closing lazygit. Called over RPC by the shim.
---@param path string
function M.edit(path)
  -- lazygit reports paths relative to the repository root, which is not
  -- necessarily Neovim's working directory.
  if vim.fn.filereadable(path) == 0 and state.root then
    local joined = vim.fs.joinpath(state.root, path)

    if vim.fn.filereadable(joined) == 1 or vim.fn.isdirectory(joined) == 1 then path = joined end
  end

  local win = target_window(state.origin)

  close()

  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  else
    vim.cmd 'new'
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
end

function M.open()
  local origin = vim.api.nvim_get_current_win()
  local cwd = vim.uv.cwd()

  local float = terminal.float('lazygit', { env = { LG_CONFIG_FILE = config_files(address()) } })

  state = {
    win = float.win,
    buf = float.buf,
    origin = origin,
    root = vim.fs.root(cwd, '.git') or cwd,
  }
end

-- `nargs = 1` keeps a path with spaces in it in one piece.
vim.api.nvim_create_user_command('LazygitOpen', function(opts) M.edit(opts.args) end, {
  nargs = 1,
  complete = 'file',
  desc = 'open a file picked in lazygit (driven by lazygit over RPC)',
})

return M
