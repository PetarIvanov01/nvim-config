local gh = require('config.pack').github

vim.pack.add { gh 'dmmulroy/tsc.nvim' }

-- The two fixes below exist because of bugs that only manifest on Windows
-- (npm's platform-specific shims; rg/find printing Windows-native backslash
-- paths). Neither needs an `is_win` guard, though, and adding one would make
-- this less portable, not more: both key off the actual runtime shell/paths
-- rather than the OS, so on a Unix machine they degrade to exactly what the
-- plugin would already do by default -- `shell_is_cmd` is always false (no
-- Unix shell path matches `cmd.exe`), and the backslash-to-forward-slash
-- gsub is a no-op (Unix paths never contain backslashes). Verified reasoning,
-- not an assumption -- if this repo is ever run on Unix and something here
-- misbehaves, that reasoning is what to re-check first.

-- tsc.nvim runs the resolved binary through `jobstart` as a shell string,
-- which goes through whichever shell config.shell has configured -- not
-- necessarily cmd.exe just because this is Windows. This config defaults to
-- Git Bash (see config/shell.lua), which cannot execute npm's `.cmd` shim
-- (confirmed: exit code 127) but runs its extensionless POSIX shim directly.
-- cmd.exe needs the opposite. Key off the actual configured shell, not the
-- platform.
local shell_is_cmd = vim.o.shell:lower():match 'cmd%.exe$' ~= nil

-- In monorepo mode, tsc.nvim discovers tsconfigs by shelling out to
-- ripgrep/find, which print Windows-native backslash paths on this platform.
-- That raw path then lands, unquoted, in a shell command string -- and a
-- POSIX shell (Git Bash, per config.shell) eats backslashes as escape
-- characters, corrupting e.g. `apps\web\tsconfig.json` into
-- `appswebtsconfig.json`. `tsc` then fails with a project-not-found error
-- that has no `(line,col)`, which the output parser doesn't recognize as an
-- error at all -- so a failed run silently reports as a clean one. Confirmed
-- directly: the raw path produces exit code 1 with a TS5058 "path does not
-- exist" error; the same path normalized to forward slashes produces the
-- real diagnostics. There's no public option for this, so patch it here --
-- forward slashes are valid on Windows regardless of shell, so this is safe
-- unconditionally, not just under bash.
local tsc_utils = require 'tsc.utils'
local find_tsconfigs = tsc_utils.find_tsconfigs
tsc_utils.find_tsconfigs = function(...)
  local configs = find_tsconfigs(...)
  for i, path in ipairs(configs) do
    configs[i] = (path:gsub('\\', '/'))
  end
  return configs
end

require('tsc').setup {
  -- Checks every tsconfig.json in the tree, not just the nearest one --
  -- matters for a monorepo (root project + apps/web, its own tsconfig).
  run_as_monorepo = true,

  -- vtsls only ever type-checks with its own bundled TypeScript, never the
  -- project's actual pinned version -- confirmed: vtsls ships 5.9.3, and
  -- TypeScript 7's package no longer even contains tsserver.js, so there is
  -- no configuration that makes vtsls use the real compiler. :TSC runs that
  -- real, pinned `tsc` and reports what it actually says, so ground-truth
  -- errors belong here rather than trusting vtsls for them. Setting this
  -- surfaces those errors as normal diagnostics (its own namespace,
  -- `tsc_diagnostics`), not just in the quickfix list.
  use_diagnostics = true,

  bin_name = shell_is_cmd and 'tsc.cmd' or 'tsc',

  -- Left at their defaults deliberately: `flags.watch` and
  -- `auto_start_watch_mode` stay off, so this only ever runs on an explicit
  -- `:TSC`, never automatically on save or on opening a buffer.
}
