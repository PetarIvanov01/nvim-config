local gh = require('config.pack').github

vim.pack.add { gh 'j-hui/fidget.nvim' }
require('fidget').setup {}

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

---@type table<string, vim.lsp.config>
local servers = {
  ts_ls = {},
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

vim.pack.add {
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'whoissethdaniel/mason-tool-installer.nvim',
}

require('mason').setup {}
require('mason-lspconfig').setup {
  automatic_enable = false,
}

local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {})

require('mason-tool-installer').setup { ensure_installed = ensure_installed }

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end
