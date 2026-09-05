local gh = require('config.pack').github

vim.pack.add { gh 'stevearc/conform.nvim' }

local conform = require 'conform'

conform.setup {
  notify_on_error = true,
  notify_no_formatters = true,
  default_format_opts = {
    lsp_format = 'fallback',
  },
  formatters = {
    -- Not one of Conform's built-ins. Ships inside Mason's `ols` package, so it
    -- arrives with the Odin language server rather than from PATH.
    odinfmt = {
      command = 'odinfmt',
      args = { '-stdin' },
      stdin = true,
      -- odinfmt finds its `odinfmt.json` by walking up from the *process* cwd,
      -- and under `-stdin` it is never told which file it is formatting. With
      -- Conform's default cwd that is Neovim's cwd, so formatting an Odin file
      -- from anywhere else silently falls back to odinfmt's built-in defaults
      -- (tabs, 100 columns) instead of the project's config -- confirmed by
      -- running `odinfmt -stdin` from inside and outside a directory holding an
      -- `odinfmt.json`. Starting it in the buffer's own directory puts that
      -- upward search back on the right path.
      cwd = function(_, ctx) return ctx.dirname end,
    },
  },
  formatters_by_ft = {
    lua = { 'stylua' },
    odin = { 'odinfmt' },
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
