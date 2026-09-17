local gh = require('config.pack').github

vim.pack.add { gh 'MeanderingProgrammer/render-markdown.nvim' }

require('render-markdown').setup {
  -- Rendered text is replaced by the raw markdown on whichever line the cursor
  -- sits on, so editing never happens against concealed characters.
  anti_conceal = { enabled = true },
  -- Signs duplicate what the rendered headings already show, and the sign
  -- column is shared with gitsigns/diagnostics here (todo-comments is likewise
  -- configured without signs).
  sign = { enabled = false },
  -- Serves callout, checkbox and link completions through an in-process LSP,
  -- which blink.cmp picks up via its existing 'lsp' source -- no extra
  -- provider registration needed.
  completions = { lsp = { enabled = true } },
}

vim.keymap.set('n', '<leader>um', '<cmd>RenderMarkdown buf_toggle<cr>', {
  desc = 'toggle [m]arkdown rendering',
})
