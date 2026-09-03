local gh = require('config.pack').github

vim.pack.add { gh 'j-hui/fidget.nvim' }
require('fidget').setup {}

-- Nvim 0.12 provides a native `:lsp` command, which makes nvim-lspconfig bail
-- out of its whole plugin/ script -- taking the `:LspLog` it used to define
-- with it. Opens at the end of the file, where the newest entries are.
vim.api.nvim_create_user_command('LspLog', function()
  local path = vim.lsp.log.get_filename()

  if vim.fn.filereadable(path) == 0 then
    vim.notify('no LSP log written yet at ' .. path, vim.log.levels.INFO)
    return
  end

  vim.cmd('tabnew ' .. vim.fn.fnameescape(path))
  vim.cmd 'normal! G'
end, { desc = 'open the LSP client log' })

vim.api.nvim_create_autocmd('lspattach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'lsp: ' .. desc })
    end

    map('grn', vim.lsp.buf.rename, '[r]e[n]ame')
    map('gra', vim.lsp.buf.code_action, '[g]oto code [a]ction', { 'n', 'x' })
    map('grD', vim.lsp.buf.declaration, '[g]oto [d]eclaration')

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/documentHighlight', event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })

      vim.api.nvim_create_autocmd({ 'cursorhold', 'cursorholdi' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'cursormoved', 'cursormovedi' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('lspdetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[t]oggle inlay [h]ints')
    end
  end,
})

vim.pack.add {
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'whoissethdaniel/mason-tool-installer.nvim',
}

local ts = require 'config.typescript'

-- `tsc` (typescript-go's native LSP) has crashed with a nil-pointer panic in
-- testing and independently with a context-canceled/EOF death in real use --
-- see project history. Until it proves stable, vtsls is the unconditional
-- default; flip this to true to make tsc primary again (still gated to
-- TypeScript 7+ projects, vtsls as its fallback) once that settles.
local prefer_tsc = false

-- Both TypeScript servers reuse vtsls's project-root logic, which resolves the
-- nearest package-manager lockfile and declines Deno projects so denols can
-- take them. Captured before vim.lsp.config() overwrites it below.
local ts_root_dir = vim.lsp.config.vtsls.root_dir

-- vtsls's inlay-hint and code-lens settings, in its own namespace (`typescript`
-- and `javascript`, not tsc's `js/ts`). javascript has no enum inlay hints or
-- implementations code lens -- JS has neither enums nor interfaces.
local function vtsls_hints(extra)
  return vim.tbl_deep_extend('force', {
    inlayHints = {
      parameterNames = { enabled = 'literals', suppressWhenArgumentMatchesName = true },
      parameterTypes = { enabled = true },
      variableTypes = { enabled = true },
      propertyDeclarationTypes = { enabled = true },
      functionLikeReturnTypes = { enabled = true },
    },
    referencesCodeLens = { enabled = true, showOnAllFunctions = true },
  }, extra or {})
end

---@type table<string, vim.lsp.config>
local servers = {
  -- TypeScript 7+. Overrides upstream's cmd/root_dir so the binary chosen by
  -- the version probe is the one actually launched; upstream's inlay-hint and
  -- code-lens settings still merge in underneath.
  tsc = {
    cmd = function(dispatchers, config)
      local root = (config or {}).root_dir or vim.fn.getcwd()
      local bin = ts.native_bin(root) or 'tsc'
      return vim.lsp.rpc.start({ bin, '--lsp', '--stdio' }, dispatchers)
    end,
    root_dir = function(bufnr, on_dir)
      if not prefer_tsc then return end
      ts_root_dir(bufnr, function(root)
        if ts.native_bin(root) then on_dir(root) end
      end)
    end,
  },
  -- Default. Also the fallback for TypeScript 5/6 projects when prefer_tsc is
  -- true, since `tsc --lsp` does not exist there.
  vtsls = {
    root_dir = function(bufnr, on_dir)
      ts_root_dir(bufnr, function(root)
        if not prefer_tsc or not ts.native_bin(root) then on_dir(root) end
      end)
    end,
    ---@type lspconfig.settings.vtsls
    settings = {
      typescript = vtsls_hints {
        inlayHints = { enumMemberValues = { enabled = true } },
        implementationsCodeLens = { enabled = true, showOnAllClassMethods = true, showOnInterfaceMethods = true },
      },
      javascript = vtsls_hints(),
    },
  },
  -- Linters. These run alongside each other: oxlint's own root_dir only
  -- attaches where the project configures oxlint, and where both are active
  -- eslint-plugin-oxlint is what suppresses the overlapping rules -- that is a
  -- project-side concern, not something to paper over here.
  --
  -- Fixes are on demand only, via :LspEslintFixAll and :LspOxlintFixAll.
  eslint = {},
  oxlint = {},
  html = {},
  cssls = {},
  lua_ls = {
    on_init = function(client)
      -- Formatting is handled by Conform and StyLua.
      client.server_capabilities.documentFormattingProvider = false

      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
      end

      local current_settings = client.config.settings --[[@as lspconfig.settings.lua_ls]]
      client.config.settings.lua = vim.tbl_deep_extend('force', current_settings.lua, {
        runtime = {
          version = 'luajit',
          path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
          checkthirdparty = false,
          -- Runtime files are needed when editing the Neovim configuration itself.
          library = vim.api.nvim_get_runtime_file('', true),
        },
      })
    end,
    ---@type lspconfig.settings.lua_ls
    settings = {
      lua = {
        format = { enable = false },
      },
    },
  },
}

require('mason').setup {}
require('mason-lspconfig').setup {
  automatic_enable = false,
}

-- `tsc` comes from the project's node_modules or $PATH, so Mason has nothing
-- to install for it and would fail to resolve the name.
local mason_ignore = { tsc = true }

local ensure_installed = {}
for name in pairs(servers) do
  if not mason_ignore[name] then ensure_installed[#ensure_installed + 1] = name end
end
vim.list_extend(ensure_installed, {})

require('mason-tool-installer').setup { ensure_installed = ensure_installed }

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end
