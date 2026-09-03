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

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'lsp: ' .. desc })
    end

    -- `grn`, `gra`, `grr`, `gri`, `grt` and `grx` are Neovim defaults since
    -- 0.11 (confirmed with `:verbose nmap gr` on 0.12.4), so they are not
    -- redefined here. `grr`/`gri`/`grt`/`grd` *are* overridden buffer-locally
    -- in plugins/telescope.lua, to swap the default quickfix list for a
    -- Telescope picker. `grD` has no Neovim default, so it is mapped here.
    map('grD', vim.lsp.buf.declaration, '[g]oto [d]eclaration')

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/documentHighlight', event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })

      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
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

    -- Code lens is off by default in Neovim (`vim.lsp.codelens.is_enabled()`
    -- returns false on a stock 0.12.4), so the `referencesCodeLens` /
    -- `implementationsCodeLens` settings requested from vtsls below were being
    -- computed by the server and then never rendered. Turn it on where the
    -- server actually provides it; `grx` (a Neovim default) runs the lens under
    -- the cursor. Remove this block to go back to no lenses.
    if client and client:supports_method('textDocument/codeLens', event.buf) then
      vim.lsp.codelens.enable(true, { bufnr = event.buf })
      map(
        '<leader>tl',
        function() vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled { bufnr = event.buf }, { bufnr = event.buf }) end,
        '[t]oggle code [l]ens'
      )
    end
  end,
})

vim.pack.add {
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'whoissethdaniel/mason-tool-installer.nvim',
}

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
  -- The TypeScript/JavaScript server for every project, regardless of the
  -- project's own TypeScript version. `tsc` (typescript-go's native `--lsp`
  -- server) was tried here and dropped after it crashed independently in
  -- testing (a nil-pointer panic) and in real use (a recurring
  -- context-canceled/EOF death) -- see commit f5e9eb3 to revive it if that
  -- ever proves stable.
  vtsls = {
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

      -- These keys are case-sensitive on the server side, unlike Vim option and
      -- autocmd names: lua-language-server flattens the settings table into
      -- dotted keys and looks each one up verbatim in its config template
      -- (script/config/config.lua, `expand()` -> `template[fullKey]`), silently
      -- dropping anything that does not match. A lowercase `lua` key made every
      -- setting below a no-op -- most visibly `workspace.library`, without which
      -- editing this config gets no Neovim API completion and an undefined-global
      -- `vim` warning. Must be `Lua`, `checkThirdParty`, `LuaJIT`.
      local current_settings = client.config.settings --[[@as lspconfig.settings.lua_ls]]
      client.config.settings.Lua = vim.tbl_deep_extend('force', current_settings.Lua, {
        runtime = {
          version = 'LuaJIT',
          path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
          checkThirdParty = false,
          -- Runtime files are needed when editing the Neovim configuration itself.
          library = vim.api.nvim_get_runtime_file('', true),
        },
      })
    end,
    ---@type lspconfig.settings.lua_ls
    settings = {
      Lua = {
        format = { enable = false },
      },
    },
  },
}

require('mason').setup {}
require('mason-lspconfig').setup {
  automatic_enable = false,
}

-- Only the language servers above. Formatters (stylua, prettier) are expected
-- on PATH or in the project, not installed by Mason -- see :checkhealth kickstart.
local ensure_installed = vim.tbl_keys(servers or {})

require('mason-tool-installer').setup { ensure_installed = ensure_installed }

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end
