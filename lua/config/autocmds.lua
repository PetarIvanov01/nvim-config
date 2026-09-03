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

-- Markdown uses trailing double-spaces as an intentional hard line break.
local trim_whitespace_excluded_filetypes = { markdown = true, diff = true }

vim.api.nvim_create_autocmd('bufwritepre', {
  desc = 'trim trailing whitespace',
  group = vim.api.nvim_create_augroup('trim-trailing-whitespace', { clear = true }),
  callback = function(ev)
    if trim_whitespace_excluded_filetypes[vim.bo[ev.buf].filetype] then return end

    local view = vim.fn.winsaveview()
    vim.cmd [[keeppatterns %s/\s\+$//e]]
    vim.fn.winrestview(view)
  end,
})
