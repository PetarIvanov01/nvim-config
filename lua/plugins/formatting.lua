local gh = require('config.pack').github

vim.pack.add { gh 'stevearc/conform.nvim' }

local conform = require 'conform'

conform.setup {
  notify_on_error = true,
  notify_no_formatters = true,
  default_format_opts = {
    lsp_format = 'fallback',
  },
  formatters_by_ft = {
    lua = { 'stylua' },
    javascript = { 'prettier' },
    javascriptreact = { 'prettier' },
    typescript = { 'prettier' },
    typescriptreact = { 'prettier' },
    html = { 'prettier' },
    css = { 'prettier' },
    json = { 'prettier' },
    jsonc = { 'prettier' },
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
  conform.format {
    async = false,
    timeout_ms = 10000,
    lsp_format = 'fallback',
  }
end, {
  desc = '[f]ormat buffer',
})
