local gh = require('config.pack').github

vim.pack.add { gh 'dmmulroy/tsc.nvim' }

local is_win = vim.fn.has 'win32' == 1

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

  -- npm creates a bare extensionless `tsc` shim in node_modules/.bin
  -- alongside `tsc.cmd`/`tsc.ps1` (confirmed present on this machine).
  -- tsc.nvim runs the resolved binary through `jobstart` as a shell string,
  -- which on Windows means cmd.exe. Given an explicit path to a file that
  -- already exists but isn't a recognized Windows executable, cmd.exe fails
  -- rather than falling back to `tsc.cmd` -- so name the .cmd variant
  -- explicitly rather than let it resolve to the POSIX shim.
  bin_name = is_win and 'tsc.cmd' or 'tsc',

  -- Left at their defaults deliberately: `flags.watch` and
  -- `auto_start_watch_mode` stay off, so this only ever runs on an explicit
  -- `:TSC`, never automatically on save or on opening a buffer.
}
