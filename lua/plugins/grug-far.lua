local gh = require('config.pack').github

-- grug-far.nvim -- project-wide find & replace in a scratch buffer.
--
-- Loaded lazily, on first use of :GrugFar / :GrugFarWithin. `load` is a no-op
-- function rather than `load = false` on purpose: `false` means `:packadd!`,
-- which puts the plugin on 'runtimepath' immediately, and Neovim then sources
-- its plugin/ files during the normal startup sequence anyway -- so it would
-- not actually be deferred. A callback is "fully responsible for loading the
-- plugin" (see :help vim.pack.add), so doing nothing here keeps grug-far off
-- 'runtimepath' entirely until the stub commands below run :packadd. It stays
-- a managed plugin either way: still installed, still pinned in
-- nvim-pack-lock.json, still picked up by `:lua vim.pack.update()`.
vim.pack.add({ gh 'MagicDuck/grug-far.nvim' }, { load = function() end })

-- Both commands the real plugin/grug-far.lua defines. :GrugFarWithin is the
-- same thing restricted to the visual selection, and is stubbed too so that
-- either entry point loads the plugin.
local commands = { 'GrugFar', 'GrugFarWithin' }

local loaded = false

local function load_grug_far()
  if loaded then return end
  loaded = true

  -- Drop the stubs before :packadd so the plugin's own definitions are the
  -- only ones left, rather than relying on create-over-existing behaviour.
  for _, name in ipairs(commands) do
    pcall(vim.api.nvim_del_user_command, name)
  end

  vim.cmd.packadd 'grug-far.nvim'

  require('grug-far').setup {
    -- Defaults for everything, deliberately. Custom options go here, e.g.:
    --   engine = 'astgrep',                                  -- 'ripgrep' (default) | 'astgrep' | 'astgrep-rules'
    --   engines = { ripgrep = { path = 'rg', extraArgs = '--hidden' } },  -- flags added to every search
    --   engines = { ripgrep = { defaults = { filesFilter = '*.ts\n*.tsx' } } },  -- pre-filled, still editable
    --   prefills = { filesFilter = '!*.test.ts', paths = 'src/' },  -- restrict to specific globs/paths
    --   windowCreationCommand = 'vsplit',                     -- how the grug-far buffer is opened
  }
end

for _, name in ipairs(commands) do
  vim.api.nvim_create_user_command(name, function(params)
    load_grug_far()

    -- Re-run the command now that the real one exists, preserving the
    -- argument (an engine name), any range, and modifiers such as :vertical.
    local range = nil
    if params.range == 1 then
      range = { params.line1 }
    elseif params.range == 2 then
      range = { params.line1, params.line2 }
    end

    vim.cmd { cmd = name, args = params.fargs, range = range, mods = params.smods }
  end, {
    -- Mirrors the real command's signature. Completion is left off; after the
    -- first invocation the plugin's own command, which completes engine
    -- names, has replaced this one.
    nargs = '?',
    range = true,
    desc = 'load grug-far.nvim, then run :' .. name,
  })
end

vim.keymap.set('n', '<leader>sr', '<cmd>GrugFar<cr>', { desc = '[s]earch and [r]eplace (grug-far)' })
