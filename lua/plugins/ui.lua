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
    { '<leader>u', group = '[u]i' },
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

local theme = require 'config.theme'
if not pcall(vim.cmd.colorscheme, theme.load()) then vim.cmd.colorscheme(theme.default) end
vim.api.nvim_set_hl(0, 'terminalnormal', {
  bg = '#11111b',
})

vim.pack.add { gh 'folke/todo-comments.nvim' }
require('todo-comments').setup { signs = false }

vim.pack.add { gh 'nvim-mini/mini.nvim' }

if vim.g.have_nerd_font then
  require('mini.icons').setup()
  MiniIcons.mock_nvim_web_devicons()
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
  },
}

vim.keymap.set('x', 's', 'c', {
  desc = 'replace selection',
})

local statusline = require 'mini.statusline'

---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return '%2l:%-2v' end

local stl_sep = vim.g.have_nerd_font and '' or '>'
local stl_dark_fg = '#1a1b26'
local stl_pos_bg = '#9ece6a'
local stl_accent = {
  Normal = '#7aa2f7',
  Insert = '#bb9af7',
  Visual = '#7dcfff',
  Replace = '#ff9e64',
  Command = '#9ece6a',
  Other = '#e0af68',
}

local function set_statusline_highlights()
  local normal_bg = vim.api.nvim_get_hl(0, { name = 'Normal' }).bg
  local box_bg = vim.api.nvim_get_hl(0, { name = 'CursorLine' }).bg or normal_bg

  for mode, color in pairs(stl_accent) do
    vim.api.nvim_set_hl(0, 'MiniStatuslineMode' .. mode, { fg = stl_dark_fg, bg = color, bold = true })
    vim.api.nvim_set_hl(0, 'StlModeSep' .. mode, { fg = color, bg = box_bg })
  end

  vim.api.nvim_set_hl(0, 'StlBox', { bg = box_bg, fg = '#c0caf5' })
  vim.api.nvim_set_hl(0, 'StlBoxSep', { fg = box_bg, bg = normal_bg })
  vim.api.nvim_set_hl(0, 'StlGit', { fg = '#565f89', bg = normal_bg })
  vim.api.nvim_set_hl(0, 'StlDiagError', { fg = '#f7768e', bg = normal_bg, bold = true })
  vim.api.nvim_set_hl(0, 'StlDiagWarn', { fg = '#e0af68', bg = normal_bg, bold = true })
  vim.api.nvim_set_hl(0, 'StlPos', { fg = stl_dark_fg, bg = stl_pos_bg, bold = true })
  vim.api.nvim_set_hl(0, 'StlPosSep', { fg = normal_bg, bg = stl_pos_bg })
end

-- mini.statusline's diagnostics section renders every severity in one color;
-- build errors and warnings separately here so they stay red/yellow.
local function stl_diagnostics()
  if not vim.diagnostic.is_enabled { bufnr = 0 } then return '' end

  local counts = vim.diagnostic.count(0)
  local severity = vim.diagnostic.severity
  local err = counts[severity.ERROR] or 0
  local warn = counts[severity.WARN] or 0
  if err == 0 and warn == 0 then return '' end

  local err_icon = vim.g.have_nerd_font and ' ' or 'E'
  local warn_icon = vim.g.have_nerd_font and ' ' or 'W'

  local parts = {}
  if err > 0 then table.insert(parts, '%#StlDiagError#' .. err_icon .. err) end
  if warn > 0 then table.insert(parts, '%#StlDiagWarn#' .. warn_icon .. warn) end
  return ' ' .. table.concat(parts, '  ') .. ' '
end

local function build_statusline()
  local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
  local mode_sep_hl = (mode_hl or ''):gsub('^MiniStatuslineMode', 'StlModeSep')

  local filename = statusline.section_filename { trunc_width = 140 }
  local git = statusline.section_git { trunc_width = 40 }
  local diff = statusline.section_diff { trunc_width = 75 }
  local location = statusline.section_location { trunc_width = 75 }

  return table.concat {
    '%#' .. mode_hl .. '# ' .. mode .. ' ',
    '%#' .. mode_sep_hl .. '#' .. stl_sep,
    '%#StlBox# ' .. filename .. ' ',
    '%#StlBoxSep#' .. stl_sep,
    '%#StlGit# ' .. git .. (diff ~= '' and ' ' .. diff or '') .. ' ',
    '%<',
    '%=',
    stl_diagnostics(),
    '%=',
    '%#StlPosSep#' .. stl_sep,
    '%#StlPos# ' .. location .. ' ',
  }
end

statusline.setup {
  use_icons = vim.g.have_nerd_font,
  content = { active = build_statusline },
}

set_statusline_highlights()

-- Re-apply colorscheme-derived highlights whenever the colorscheme changes
-- (e.g. via the <leader>uc picker), since ':colorscheme' clears all highlights first.
local function apply_dynamic_highlights()
  fix_bufferline_backgrounds()
  set_statusline_highlights()
end

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('dynamic-ui-highlights', { clear = true }),
  callback = apply_dynamic_highlights,
})

apply_dynamic_highlights()
