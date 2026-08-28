vim.api.nvim_create_autocmd('textyankpost', {
  desc = 'highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd('termopen', {
  desc = 'use custom terminal background',
  group = vim.api.nvim_create_augroup('custom-terminal-highlight', { clear = true }),
  callback = function()
    vim.wo.winhighlight = table.concat({
      'normal:terminalnormal',
      'normalnc:terminalnormal',
      'signcolumn:terminalnormal',
      'endofbuffer:terminalnormal',
    }, ',')
  end,
})
