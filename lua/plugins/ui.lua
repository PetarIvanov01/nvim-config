local gh = require('config.pack').github

vim.pack.add { gh 'nmac427/guess-indent.nvim' }
require('guess-indent').setup {}

vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
require('gitsigns').setup {
  signs = {
    add = { text = '+' }, ---@diagnostic disable-line: missing-fields
    change = { text = '~' }, ---@diagnostic disable-line: missing-fields
    delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
    topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
    changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
  },
}

vim.pack.add { gh 'folke/which-key.nvim' }
require('which-key').setup {
  delay = 0,
  icons = { mappings = vim.g.have_nerd_font },
  spec = {
    { '<leader>s', group = '[s]earch', mode = { 'n', 'v' } },
    { '<leader>t', group = '[t]erminal' },
    { '<leader>h', group = 'git [h]unk', mode = { 'n', 'v' } },
    { 'gr', group = 'lsp actions', mode = { 'n' } },
  },
}

vim.pack.add { gh 'mg979/vim-visual-multi' }

vim.pack.add { gh 'folke/tokyonight.nvim' }
---@diagnostic disable-next-line: missing-fields
require('tokyonight').setup {
  styles = {
    comments = { italic = false },
  },
}

vim.cmd.colorscheme 'tokyonight-night'
vim.api.nvim_set_hl(0, 'terminalnormal', {
  bg = '#11111b',
})

vim.pack.add { gh 'folke/todo-comments.nvim' }
require('todo-comments').setup { signs = false }

vim.pack.add { gh 'nvim-mini/mini.nvim' }

if vim.g.have_nerd_font then
  require('mini.icons').setup()
  miniicons.mock_nvim_web_devicons()
end

vim.pack.add { gh 'akinsho/bufferline.nvim' }

local bufferline = require 'bufferline'
local normal_bg = {
  attribute = 'bg',
  highlight = 'normal',
}

bufferline.setup {
  options = {
    style_preset = bufferline.style_preset.minimal,
    indicator = {
      style = 'none',
    },
    separator_style = { '', '' },
    show_buffer_close_icons = true,
    show_close_icon = false,
    custom_filter = function(bufnr)
      local buftype = vim.bo[bufnr].buftype
      local name = vim.api.nvim_buf_get_name(bufnr)

      if buftype == 'terminal' then return false end
      if name == '' and not vim.bo[bufnr].modified then return false end

      return true
    end,
  },
  highlights = {
    fill = {
      bg = normal_bg,
    },
    background = {
      bg = normal_bg,
      fg = '#565f89',
    },
    buffer_visible = {
      bg = normal_bg,
      fg = '#a9b1d6',
    },
    buffer_selected = {
      bg = normal_bg,
      fg = '#7aa2f7',
      bold = true,
      italic = false,
    },
    separator = {
      bg = normal_bg,
      fg = normal_bg,
    },
    separator_visible = {
      bg = normal_bg,
      fg = normal_bg,
    },
    separator_selected = {
      bg = normal_bg,
      fg = normal_bg,
    },
    indicator_selected = {
      bg = normal_bg,
      fg = normal_bg,
    },
    close_button = {
      bg = normal_bg,
      fg = '#565f89',
    },
    close_button_visible = {
      bg = normal_bg,
      fg = '#565f89',
    },
    close_button_selected = {
      bg = normal_bg,
      fg = '#7aa2f7',
    },
    modified = {
      bg = normal_bg,
    },
    modified_visible = {
      bg = normal_bg,
    },
    modified_selected = {
      bg = normal_bg,
    },
  },
}

-- Bufferline's setup does not consistently resolve linked backgrounds.
local function fix_bufferline_backgrounds()
  local normal = vim.api.nvim_get_hl(0, { name = 'normal' })
  local bg = normal.bg

  local groups = {
    'bufferlinefill',
    'bufferlinebackground',
    'bufferlinebuffervisible',
    'bufferlinebufferselected',
    'bufferlineseparator',
    'bufferlineseparatorvisible',
    'bufferlineseparatorselected',
    'bufferlineindicatorselected',
    'bufferlineclosebutton',
    'bufferlineclosebuttonvisible',
    'bufferlineclosebuttonselected',
    'bufferlinemodified',
    'bufferlinemodifiedvisible',
    'bufferlinemodifiedselected',
  }

  for _, group in ipairs(groups) do
    local hl = vim.api.nvim_get_hl(0, { name = group })
    hl.bg = bg
    vim.api.nvim_set_hl(0, group, hl)
  end
end

fix_bufferline_backgrounds()

require('mini.ai').setup {
  -- Avoid conflicts with Neovim's built-in incremental selection mappings.
  mappings = {
    around_next = 'aa',
    inside_next = 'ii',
  },
  n_lines = 500,
}

require('mini.surround').setup {
  mappings = {
    add = 'gsa',
    delete = 'gsd',
    find = 'gsf',
    find_left = 'gsf',
    highlight = 'gsh',
    replace = 'gsr',
    update_n_lines = 'gsn',
  },
}

vim.keymap.set('x', 's', 'c', {
  desc = 'replace selection',
})

local statusline = require 'mini.statusline'
statusline.setup { use_icons = vim.g.have_nerd_font }

---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return '%2l:%-2v' end
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_fileinfo = function() return '%y' end
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_git = function()
  local branch = vim.b.gitsigns_head
  if not branch or branch == '' then return '' end
  return branch
end
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_diff = function() return '' end
