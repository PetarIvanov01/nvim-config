local M = {}

M.selected = 'bash'

M.profiles = {
  bash = {
    executable = 'C:/Users/petar.iva/AppData/Local/Programs/Git/bin/bash.exe',
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
