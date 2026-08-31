local M = {}

M.selected = 'bash'

---@return string[]
local function candidate_git_roots()
  local roots = {}

  -- Git for Windows ships git.exe under <root>/bin or <root>/cmd and
  -- bash.exe under <root>/bin, so derive the root from whatever `git` the
  -- shell would actually run.
  local git_exe = vim.fn.exepath 'git'
  if git_exe ~= '' then table.insert(roots, vim.fs.dirname(vim.fs.dirname(git_exe))) end

  for _, env_name in ipairs { 'ProgramFiles', 'ProgramFiles(x86)' } do
    local dir = vim.env[env_name]
    if dir then table.insert(roots, dir .. '/Git') end
  end

  -- Per-user installs (the installer's default when not run as admin).
  if vim.env.LOCALAPPDATA then table.insert(roots, vim.env.LOCALAPPDATA .. '/Programs/Git') end

  return roots
end

---Locate Git for Windows' bash.exe without hardcoding a machine-specific path.
---@return string
local function find_git_bash()
  for _, root in ipairs(candidate_git_roots()) do
    local candidate = root .. '/bin/bash.exe'
    if vim.uv.fs_stat(candidate) then return candidate end
  end

  -- Fall back to whatever `bash` resolves to on PATH.
  return vim.fn.exepath 'bash'
end

M.profiles = {
  bash = {
    executable = find_git_bash(),
    terminal_args = { '--login', '-i' },
    shellcmdflag = '-c',
    shellquote = '',
    shellxquote = '',
    shellpipe = '2>&1| tee',
    shellredir = '>%s 2>&1',
  },
  cmd = {
    executable = 'cmd.exe',
    terminal_args = {},
    shellcmdflag = '/s /c',
    shellquote = '',
    shellxquote = '"',
    shellpipe = '2>&1| tee',
    shellredir = '>%s 2>&1',
  },
  powershell = {
    executable = 'powershell.exe',
    terminal_args = {},
    shellcmdflag = table.concat({
      '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command',
      '[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();',
      "$PSDefaultParameterValues['Out-File:Encoding']='utf8';",
    }, ' '),
    shellquote = '',
    shellxquote = '',
    shellpipe = '> %s 2>&1',
    shellredir = '>%s 2>&1',
  },
}

function M.setup(name)
  name = name or M.selected

  local profile = M.profiles[name]
  assert(profile, ('unknown shell profile: %s'):format(name))

  if profile.executable == '' then
    vim.notify(('shell profile %q: could not locate its executable; falling back to Neovim defaults'):format(name), vim.log.levels.WARN)
    return
  end

  M.selected = name

  vim.o.shell = profile.executable
  vim.o.shellcmdflag = profile.shellcmdflag
  vim.o.shellquote = profile.shellquote
  vim.o.shellxquote = profile.shellxquote
  vim.o.shellpipe = profile.shellpipe
  vim.o.shellredir = profile.shellredir
  vim.o.shelltemp = false
end

function M.terminal_command()
  local profile = M.profiles[M.selected]
  return vim.list_extend({ profile.executable }, profile.terminal_args)
end

M.setup()

return M
