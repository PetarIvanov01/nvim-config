-- Picks the TypeScript language server per project root.
--
-- TypeScript 7 ships its own server (`tsc --lsp --stdio`), but only 7.0+
-- understands `--lsp`. Projects still on TypeScript 5/6 need vtsls instead.
-- Both servers claim the same filetypes, so each one's root_dir consults
-- native_bin() and exactly one of them attaches.
--
-- This deliberately differs from nvim-lspconfig's own lsp/tsc.lua, which
-- skips an outdated node_modules binary in favour of a newer one on $PATH.
-- That is the right call when tsc is the only candidate, but here it would let
-- a globally installed TypeScript 7 serve a project pinned to TypeScript 5 --
-- type-checking it against a compiler the project does not build with, and
-- starving vtsls of every project it exists to handle. So the project's own
-- pin decides, and $PATH is consulted only when the project pins nothing.

local M = {}

local is_win = vim.fn.has 'win32' == 1

---@type table<string, string|false>
local resolved = {}

--- The binary a project pins in node_modules, resolving the shim Windows needs.
---@param root string
---@param name string
---@return string|nil
local function pinned_bin(root, name)
  local base = vim.fs.joinpath(root, 'node_modules/.bin', name)
  for _, ext in ipairs(is_win and { '.cmd', '' } or { '' }) do
    if vim.fn.filereadable(base .. ext) == 1 then return base .. ext end
  end
end

--- Whether `bin` is a TypeScript binary new enough to speak `--lsp`.
---@param bin string
---@return boolean
local function supports_lsp(bin)
  local out = vim.system({ bin, '--version' }, { text = true }):wait()
  local version = vim.version.parse(out.stdout or '')

  return out.code == 0 and version ~= nil and version.major >= 7
end

--- The TypeScript binary serving `root`, or nil when the project is pre-7.0.
--- Cached per root, including misses, because probing shells out.
---@param root string
---@return string|nil
function M.native_bin(root)
  if resolved[root] ~= nil then return resolved[root] or nil end

  local function decide()
    -- A project that pins TypeScript decides on its own version alone: if the
    -- pin is pre-7.0, vtsls takes it rather than $PATH overriding the pin.
    for _, name in ipairs { 'tsc', 'tsgo' } do
      local pinned = pinned_bin(root, name)
      if pinned then return supports_lsp(pinned) and pinned or nil end
    end

    -- No pin, so whatever is on $PATH is the project's TypeScript.
    for _, name in ipairs { 'tsc', 'tsgo' } do
      if vim.fn.executable(name) == 1 and supports_lsp(name) then return name end
    end
  end

  local bin = decide()
  resolved[root] = bin or false
  return bin
end

--- Which server won each resolved root, for debugging: `:lua require('config.typescript').report()`
function M.report()
  local lines = {}
  for root, bin in pairs(resolved) do
    lines[#lines + 1] = ('%s -> %s'):format(root, bin and ('tsc (' .. bin .. ')') or 'vtsls')
  end
  if #lines == 0 then lines[1] = 'no TypeScript project roots resolved yet' end
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
end

return M
