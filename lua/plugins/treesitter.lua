local gh = require('config.pack').github

vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.o.foldenable = true
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99

local parsers = {
  'bash',
  'c',
  'css',
  'diff',
  'html',
  'javascript',
  'jsdoc',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
}

require('nvim-treesitter').install(parsers)

---@param buf integer
---@param language string
local function treesitter_try_attach(buf, language)
  if not vim.treesitter.language.add(language) then return end
  vim.treesitter.start(buf, language)

  local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil
  if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
end

local available_parsers = require('nvim-treesitter').get_available()

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local buf, filetype = args.buf, args.match
    local language = vim.treesitter.language.get_lang(filetype)
    if not language then return end

    local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

    if vim.tbl_contains(installed_parsers, language) then
      treesitter_try_attach(buf, language)
    elseif vim.tbl_contains(available_parsers, language) then
      require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
    else
      treesitter_try_attach(buf, language)
    end
  end,
})
