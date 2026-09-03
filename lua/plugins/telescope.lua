local gh = require('config.pack').github

---@type (string|vim.pack.spec)[]
local telescope_plugins = {
  gh 'nvim-lua/plenary.nvim',
  gh 'nvim-telescope/telescope.nvim',
  gh 'nvim-telescope/telescope-ui-select.nvim',
  gh 'nvim-telescope/telescope-live-grep-args.nvim',
}

if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

vim.pack.add(telescope_plugins)

local lga_actions = require 'telescope-live-grep-args.actions'

require('telescope').setup {
  extensions = {
    ['ui-select'] = { require('telescope.themes').get_dropdown() },
    live_grep_args = {
      auto_quoting = true,
      mappings = {
        i = {
          ['<C-k>'] = lga_actions.quote_prompt(),
          ['<C-i>'] = lga_actions.quote_prompt { postfix = ' --iglob ' },
        },
      },
    },
  },
}

pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'ui-select')
pcall(require('telescope').load_extension, 'live_grep_args')

local builtin = require 'telescope.builtin'

vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[s]earch [h]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[s]earch [k]eymaps' })
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[s]earch [f]iles' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[s]earch [s]elect telescope' })
vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[s]earch current [w]ord' })
vim.keymap.set(
  'n',
  '<leader>sg',
  function() require('telescope').extensions.live_grep_args.live_grep_args() end,
  { desc = '[s]earch by [g]rep' }
)
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[s]earch [d]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[s]earch [r]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[s]earch recent files ("." for repeat)' })
vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[s]earch [c]ommands' })
vim.keymap.set('n', '<leader><leader>', require('telescope.builtin').find_files, { desc = '[ ] find files' })

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
  callback = function(event)
    local buf = event.buf

    vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[g]oto [r]eferences' })
    vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[g]oto [i]mplementation' })
    vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[g]oto [d]efinition' })
    vim.keymap.set('n', 'go', builtin.lsp_document_symbols, { buffer = buf, desc = 'open document symbols' })
    vim.keymap.set('n', 'gw', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'open workspace symbols' })
    vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[g]oto [t]ype definition' })
  end,
})

vim.keymap.set(
  'n',
  '<leader>/',
  function()
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end,
  { desc = '[/] fuzzily search in current buffer' }
)

vim.keymap.set(
  'n',
  '<leader>s/',
  function()
    builtin.live_grep {
      grep_open_files = true,
      prompt_title = 'live grep in open files',
    }
  end,
  { desc = '[s]earch [/] in open files' }
)

vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true } end, { desc = '[s]earch [n]eovim files' })

vim.keymap.set('n', '<leader>bn', '<cmd>bnext<cr>', {
  desc = '[b]uffer [n]ext',
})

vim.keymap.set('n', '<leader>bp', '<cmd>bprevious<cr>', {
  desc = '[b]uffer [p]revious',
})

vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<cr>', {
  desc = '[b]uffer [d]elete',
})

vim.keymap.set('n', '<leader>bb', '<cmd>enew<cr>', {
  desc = '[b]uffer new',
})

vim.keymap.set('n', '<leader>sb', require('telescope.builtin').buffers, {
  desc = '[s]earch [b]uffers',
})

local theme_state = require 'config.theme'
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

vim.keymap.set('n', '<leader>uc', function()
  builtin.colorscheme {
    enable_preview = true,
    attach_mappings = function(_, _)
      actions.select_default:enhance {
        post = function()
          local entry = action_state.get_selected_entry()
          if entry then theme_state.save(entry.value) end
        end,
      }
      return true
    end,
  }
end, { desc = '[u]i [c]olorscheme picker' })
