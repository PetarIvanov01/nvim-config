--[[
--
-- Health checks for this configuration, run with `:checkhealth kickstart`.
--
-- This is not required for the config to work; it exists so that a missing
-- external tool shows up here instead of as a silent failure the first time a
-- mapping is pressed. Keep the tool lists below in sync with README.md's
-- Requirements section.
--
--]]

local check_version = function()
  local verstr = tostring(vim.version())
  if not vim.version.ge then
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
    return
  end

  -- 0.12 is a hard floor, not a preference: this config uses `vim.pack`, the
  -- native `:lsp` command's presence, and `vim.lsp.codelens.enable()`.
  if vim.version.ge(vim.version(), '0.12') then
    vim.health.ok(string.format("Neovim version is: '%s'", verstr))
  else
    vim.health.error(string.format("Neovim out of date: '%s'. This config requires 0.12 or newer", verstr))
  end
end

-- Tools the config cannot work without.
local required = {
  { exe = 'git', reason = 'vim.pack clones and updates every plugin with it' },
  { exe = 'rg', reason = "Telescope live grep (<leader>sg), grep_string (<leader>sw), and :TSC's tsconfig discovery" },
}

local is_win = vim.fn.has 'win32' == 1

-- Tools that disable one feature each when missing, rather than breaking
-- startup. `when = false` drops an entry that cannot apply on this platform --
-- a warning for a tool nothing here would ever call is just noise.
local optional = {
  -- On Windows `make` costs exactly one thing: the native fzf sorter. The other
  -- build hook it drives, LuaSnip's jsregexp, is guarded by `has('win32') ~= 1`
  -- in config/pack.lua, so it is skipped on this platform whether or not `make`
  -- exists -- installing `make` would not bring it back.
  {
    exe = 'make',
    reason = 'telescope-fzf-native is never added to vim.pack at all without it (plugins/telescope.lua)'
      .. (is_win and '' or "; LuaSnip's jsregexp is not built"),
  },
  -- Mason only shells out to `unzip` on Unix; on Windows it extracts with
  -- PowerShell's Expand-Archive instead (mason-core/installer/managers/std.lua,
  -- `platform.when { unix = ..., win = ... }`), and Mason's own health check
  -- treats unzip as relaxed. Nothing here would call it on Windows.
  { exe = 'unzip', reason = 'some Mason packages cannot be extracted', when = not is_win },
  { exe = 'lazygit', reason = 'the floating Git UI on <leader>gg' },
  { exe = 'stylua', reason = 'Lua formatting on <leader>f; Conform falls back to LSP formatting' },
  { exe = 'prettier', reason = 'JS/TS/HTML/CSS/JSON formatting on <leader>f; Conform falls back to LSP formatting' },
  { exe = 'node', reason = 'vtsls, eslint and oxlint all run on Node' },
  -- ols and odinfmt themselves are installed by Mason with the rest of the
  -- language servers, so they are not checked here -- but the Odin compiler is
  -- not, and ols shells out to it to type-check and to resolve the core/vendor
  -- collections. Without it the server still attaches and still completes, it
  -- just stops reporting real errors.
  { exe = 'odin', reason = "ols's type checking and its core/vendor collections; completion still works without it" },
  -- tsc.nvim searches upward for node_modules/.bin/tsc first (utils.find_tsc_bin)
  -- and only falls back to PATH, so this warning is harmless inside a project
  -- that has TypeScript installed -- which is the case :TSC is built for.
  { exe = 'tsc', reason = ':TSC outside a project that has its own node_modules/.bin/tsc' },
}

local check_external_reqs = function()
  for _, tool in ipairs(required) do
    if vim.fn.executable(tool.exe) == 1 then
      vim.health.ok(string.format("Found required executable: '%s'", tool.exe))
    else
      vim.health.error(string.format("Missing required executable: '%s' -- %s", tool.exe, tool.reason))
    end
  end

  for _, tool in ipairs(optional) do
    if tool.when == false then
      -- Not applicable on this platform; say so once instead of warning forever.
      vim.health.info(string.format("Skipped check for '%s' -- not used on this platform", tool.exe))
    elseif vim.fn.executable(tool.exe) == 1 then
      vim.health.ok(string.format("Found executable: '%s'", tool.exe))
    else
      vim.health.warn(string.format("Could not find executable: '%s' -- %s", tool.exe, tool.reason))
    end
  end
end

-- config/shell.lua locates Git Bash by probing several install locations and
-- silently falls back to Neovim's defaults when it finds nothing, which is easy
-- to miss until `:!` or <leader>tt behaves unexpectedly.
local check_shell = function()
  local ok, shell = pcall(require, 'config.shell')
  if not ok then
    vim.health.error('could not load config.shell: ' .. tostring(shell))
    return
  end

  local profile = shell.profiles[shell.selected]
  if not profile then
    vim.health.error(string.format('selected shell profile %q is not defined in config/shell.lua', shell.selected))
    return
  end

  if profile.executable == '' then
    vim.health.error(string.format("shell profile %q: could not locate its executable; Neovim's default shell is in use", shell.selected))
  elseif vim.fn.executable(profile.executable) == 1 then
    vim.health.ok(string.format('shell profile %q resolves to: %s', shell.selected, profile.executable))
  else
    vim.health.warn(string.format('shell profile %q points at %s, which is not executable', shell.selected, profile.executable))
  end
end

return {
  check = function()
    vim.health.start 'nvim config'

    vim.health.info [[NOTE: Not every warning is a 'must-fix' in `:checkhealth`

  Fix only warnings for the features you actually use -- each optional tool
  below names the one feature it affects.]]

    local uv = vim.uv or vim.loop
    vim.health.info('System Information: ' .. vim.inspect(uv.os_uname()))

    check_version()
    check_external_reqs()
    check_shell()
  end,
}
