local map = vim.keymap.set

map('n', '<s-h>', '<cmd>bprevious<cr>', { desc = 'previous buffer' })
map('n', '<s-l>', '<cmd>bnext<cr>', { desc = 'next buffer' })

map('n', '<leader>v', '<cmd>vsplit<cr>', { desc = 'vertical split' })

map('n', '<leader>h', '<c-w>h', { desc = 'window left' })
map('n', '<leader>j', '<c-w>j', { desc = 'window down' })
map('n', '<leader>k', '<c-w>k', { desc = 'window up' })
map('n', '<leader>l', '<c-w>l', { desc = 'window right' })

map('n', '<a-j>', ':m .+1<cr>==', { desc = 'move line down' })
map('n', '<a-k>', ':m .-2<cr>==', { desc = 'move line up' })
map('v', '<a-j>', ":m '>+1<cr>gv=gv", { desc = 'move selection down' })
map('v', '<a-k>', ":m '<-2<cr>gv=gv", { desc = 'move selection up' })

map('n', '<leader>e', '<Cmd>Neotree toggle reveal<CR>', {
  desc = 'toggle file explorer',
})

map('i', '<c-l>', function() require('blink.cmp').show() end, {
  desc = 'show completion',
})

local terminal = require 'custom.terminal'

map('n', '<leader>gg', function() terminal.float 'lazygit' end, {
  desc = '[g]it lazy[g]it',
})
map({ 'n' }, '<leader>tt', terminal.toggle, { desc = 'toggle terminal' })
map({ 'n' }, '<leader>tf', terminal.focus, { desc = 'focus terminal' })
map({ 'n' }, '<leader>tn', terminal.new, { desc = 'new terminal' })
map({ 'n' }, '<leader>t]', terminal.next, { desc = 'next terminal' })
map({ 'n' }, '<leader>t[', terminal.prev, { desc = 'previous terminal' })
map({ 'n' }, '<leader>tc', terminal.close, { desc = 'close current terminal' })

map('n', '<esc>', '<cmd>nohlsearch<cr>')

vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  -- virtual_text renders inline at end-of-line with no wrapping and no
  -- affordance to see the rest -- a long TypeScript message (union types
  -- especially) just runs off the window edge with nothing visibly wrong.
  -- virtual_lines at least moves it off the code line and onto its own,
  -- horizontally scrollable one (Neovim's virt_lines default to
  -- `virt_lines_overflow = 'scroll'`, confirmed in vim/diagnostic.lua) --
  -- better, but still not wrapped: 'wrap' does not apply to virtual lines
  -- (see `:h nvim_buf_set_extmark()`). current_line keeps every other
  -- diagnostic in the buffer as just an underline (still configured above).
  -- For a guaranteed, fully wrapped read of a long message, use <leader>d
  -- below -- it opens the same kind of floating window as hover, which
  -- genuinely soft-wraps by default (vim/lsp/util.lua: `opts.wrap = opts.wrap
  -- ~= false`).
  virtual_text = false,
  virtual_lines = { current_line = true },
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float {
        bufnr = bufnr,
        scope = 'cursor',
        focus = false,
      }
    end,
  },
}

map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'open diagnostic [q]uickfix list' })
map('n', '<leader>d', function()
  vim.diagnostic.open_float { scope = 'cursor', focus = true }
end, { desc = 'open [d]iagnostic float (focused, fully wrapped, scrollable)' })
map('t', '<esc><esc>', '<c-\\><c-n>', { desc = 'exit terminal mode' })

map('n', '<c-h>', '<c-w><c-h>', { desc = 'move focus to the left window' })
map('n', '<c-l>', '<c-w><c-l>', { desc = 'move focus to the right window' })
map('n', '<c-j>', '<c-w><c-j>', { desc = 'move focus to the lower window' })
map('n', '<c-k>', '<c-w><c-k>', { desc = 'move focus to the upper window' })
