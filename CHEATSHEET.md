## Save, quit, undo, and modes

| Key or command | Action |
| --- | --- |
| `i` / `a` | Insert before / after the cursor |
| `I` / `A` | Insert at first nonblank / append at end of line |
| `o` / `O` | Open a new line below / above |
| `<Esc>` | Return to Normal mode; also clears search highlighting in this config |
| `v` / `V` / `<C-v>` | Character / line / block Visual mode |
| `u` / `<C-r>` | Undo / redo |
| `.` | Repeat the last change |
| `:w` | Save current file |
| `:wa` | Save all changed files |
| `:q` / `:q!` | Quit / quit and discard changes |
| `:wq` / `ZZ` | Save and quit |
| `ZQ` | Quit without saving |
| `:qa` / `:qa!` | Quit all / force quit all |

## Movement and selection

| Key | Action |
| --- | --- |
| `h j k l` | Left, down, up, right |
| `w` / `b` / `e` | Next word, previous word, end of word |
| `W` / `B` / `E` | Same movements using whitespace-delimited WORDs |
| `0` / `^` / `$` | Start, first nonblank, end of line |
| `gg` / `G` / `{line}G` | First line, last line, specific line |
| `{` / `}` | Previous / next paragraph or block boundary |
| `%` | Jump between matching brackets or language constructs |
| `f{x}` / `F{x}` | Move to character forward / backward |
| `t{x}` / `T{x}` | Move just before character forward / backward |
| `;` / `,` | Repeat / reverse the last `f`, `F`, `t`, or `T` |
| `M` | Middle visible screen line (`H` and `L` are remapped to buffer switching) |
| `<C-d>` / `<C-u>` | Half-page down / up |
| `<C-f>` / `<C-b>` | Full-page forward / backward |
| `zz` / `zt` / `zb` | Center / top / bottom the current line |
| `gv` | Reselect the previous Visual selection |
| `o` in Visual mode | Move to the other end of the selection |

## Common editing

| Key | Action |
| --- | --- |
| `x` / `X` | Delete character under / before cursor |
| `dd` / `D` | Delete line / to end of line |
| `cc` / `C` | Change line / to end of line |
| `yy` / `Y` | Yank line / yank to end of line (`Y` is `y$`, not `yy`) |
| `p` / `P` | Paste after / before cursor |
| `r{x}` / `R` | Replace one character / enter Replace mode |
| `J` | Join current line with the next |
| `~` | Toggle character case |
| `gu{motion}` / `gU{motion}` | Make text lowercase / uppercase |
| `>>` / `<<` | Indent / unindent current line |
| `=` with a motion | Reindent, for example `=ip` or `gg=G` |
| `<A-j>` / `<A-k>` | Move current line down / up and reindent |
| Visual `<A-j>` / `<A-k>` | Move selected lines down / up |
| Visual `s` | Change the selection (`c`) |

## Search

| Key or command | Action |
| --- | --- |
| `/pattern` / `?pattern` | Search forward / backward |
| `n` / `N` | Next / previous search match |
| `*` / `#` | Search forward / backward for word under cursor |
| `g*` / `g#` | Search current word without word boundaries |
| `/\cword` / `/\Cword` | Force case-insensitive / case-sensitive search |
| `:noh` | Clear search highlighting (`<Esc>` also does this here) |
| `:vimgrep /pattern/g **/*` | Search files into the quickfix list |

## Substitute and replace

| Command | Action |
| --- | --- |
| `:s/old/new/` | Replace first match on current line |
| `:s/old/new/g` | Replace every match on current line |
| `:%s/old/new/g` | Replace every match in the file |
| `:%s/old/new/gc` | Replace throughout file and confirm each match |
| `:%s/\<old\>/new/gc` | Confirm replacement of whole-word matches only |
| `:%s//new/g` | Replace the last searched pattern |
| `:'<,'>s/old/new/g` | Replace inside the current Visual selection |
| `:%s#old/path#new/path#g` | Use `#` as separator when text contains `/` |
| `:%s/old/&-suffix/g` | `&` inserts the complete matched text in replacement |
| `:%s/old/\=toupper(submatch(0))/g` | Use a Vim expression as replacement |
| `:cfdo %s/old/new/gc \| update` | Replace across every file in quickfix list |

Confirmation keys for `c`: `y` replace, `n` skip, `a` replace all remaining, `q` quit, `l` replace then quit.

## Yank, paste, registers, and multiple buffers

Registers are global to the Neovim session, so text yanked in one buffer can be pasted in another.

| Key or command | Action |
| --- | --- |
| `yy` / `{visual}y` | Yank a line / selection |
| `"ayy` | Yank line into named register `a` |
| `"ap` / `"aP` | Paste register `a` after / before cursor |
| `"Ayy` | Append a line to register `a` |
| `"0p` | Paste the most recent yank, ignoring later deletes |
| `"+y` / `"+p` | Yank to / paste from the system clipboard |
| `"*y` / `"*p` | Yank to / paste from the selection clipboard |
| `"_d` / `"_x` | Delete without overwriting useful registers |
| `:registers` / `:registers a` | Show all registers / register `a` |
| `<C-r>a` in Insert mode | Insert register `a` without leaving Insert mode |
| `<C-r>+` in Insert mode | Insert system clipboard contents |

Cross-buffer recipe:

1. In source buffer: `"ayy` or visually select and press `"ay`.
2. Switch buffer with `<S-h>`, `<S-l>`, or `<leader>sb`.
3. In destination buffer: `"ap`.

Because `clipboard=unnamedplus` is enabled, ordinary yanks and pastes also integrate with the Windows clipboard.

## Macros and repetition

| Key or command | Action |
| --- | --- |
| `qa` | Start recording macro into register `a` |
| `q` | Stop recording |
| `@a` | Run macro `a` |
| `@@` | Repeat the last executed macro |
| `10@a` | Run macro `a` ten times |
| `:registers a` | Inspect macro `a` |
| `:let @a='...'` | Replace macro `a` with explicit keystrokes/text |
| `:'<,'>normal @a` | Run macro `a` once on every selected line |
| `.` | Repeat the most recent edit instead of recording a macro |
| `&` / `g&` | Repeat last substitution on current line / globally |

Reliable macro recipe: place cursor consistently → `qa` → perform one complete edit → move to the next target → `q` → test with `@a` → repeat with a count.

## Marks, jumps, and change history

| Key or command | Action |
| --- | --- |
| `m{a-z}` | Set a lowercase mark local to the current buffer |
| `m{A-Z}` | Set a global mark that remembers its file |
| `` `{mark} `` | Jump to the mark's exact line and column |
| `'{mark}` | Jump to the mark's line, at its first nonblank character |
| `ma` → `` `a `` | Set local mark `a`, then return to its exact position |
| `mA` → `` `A `` | Set global mark `A`, then return to it from any file |
| `''` | Jump to the line used before the latest jump |
| <code>``</code> | Jump to the exact position used before the latest jump |
| `<C-o>` / `<C-i>` | Move backward / forward through jump history |
| `g;` / `g,` | Previous / next change position |
| `:jumps` / `:changes` / `:marks` | Inspect jump, change, or mark history |
| `:marks aA0` | Display only the listed marks |
| `:delmarks a` / `:delmarks a-d` | Delete one mark / a range of marks |
| `:delmarks!` | Delete all lowercase marks in the current buffer |

### Automatic and special marks

| Mark | Jump target |
| --- | --- |
| `` `. `` / `'.` | Exact position / line of the last change |
| `` `^ `` / `'^` | Exact position / line where Insert mode last stopped |
| `` `[ `` / `` `] `` | Start / end of the last changed or yanked text |
| `` `< `` / `` `> `` | Start / end of the last Visual selection |
| `` `" `` / `'"` | Exact position / line used when the buffer was last closed |
| `` `0 `` | Position in the last file edited before Neovim exited |
| `` `1 `` … `` `9 `` | Older file positions stored in ShaDa history |

Mark workflow across files: set `mA` in the source file → navigate anywhere → press `` `A `` to return exactly. Lowercase marks (`a-z`) stay within one buffer; uppercase marks (`A-Z`) are intended for cross-file navigation.

## Buffers, windows, and tabs

| Key or command | Action |
| --- | --- |
| `<S-h>` (`H`) / `<leader>bp` | Previous buffer |
| `<S-l>` (`L`) / `<leader>bn` | Next buffer |
| `<leader>bb` | New empty buffer |
| `<leader>bd` | Delete current buffer |
| `<leader>sb` | Search buffers with Telescope |
| `:buffers` | List buffers; jump with `:buffer {number}` |
| `:b#` | Switch to alternate buffer |
| `<leader>v` / `:vsplit` | Create vertical split |
| `:split` | Create horizontal split |
| `<leader>h/j/k/l` | Focus left/down/up/right window |
| `<C-h/j/k/l>` | Focus left/down/up/right window |
| `<C-w>=` | Equalize split sizes |
| `<C-w>_` / `<C-w>|` | Maximize height / width |
| `<C-w>q` | Close current window |
| `:tabnew` / `:tabclose` | Create / close a tab page |
| `gt` / `gT` | Next / previous tab page |

## Telescope search and navigation

| Key | Action |
| --- | --- |
| `<leader><leader>` / `<leader>sf` | Find files |
| `<leader>sg` | Live grep project text |
| `<leader>sw` | Search word under cursor or Visual selection |
| `<leader>sh` | Search help tags |
| `<leader>sk` | Search active keymaps |
| `<leader>ss` | Select a Telescope picker |
| `<leader>sd` | Search diagnostics |
| `<leader>sr` | Resume previous picker |
| `<leader>s.` | Search recent files |
| `<leader>sc` | Search commands |
| `<leader>sn` | Search Neovim configuration files |
| `<leader>sb` | Search open buffers |
| `<leader>/` | Fuzzy-search current buffer |
| `<leader>s/` | Live-grep open files only |
| `:Telescope builtin` | Choose any Telescope picker |

Inside Telescope, use `<C-n>` / `<C-p>` to move, `<CR>` to open, and `<C-/>` in Insert mode or `?` in Normal mode to display picker mappings.

## LSP and diagnostics

These mappings appear only when a language server attaches to the buffer.

| Key or command | Action |
| --- | --- |
| `K` | Show hover documentation, arguments, parameter types, and return type |
| `grd` | Find definitions with Telescope |
| `grD` | Go to declaration |
| `grr` | Find references with Telescope |
| `gri` | Find implementations with Telescope |
| `grt` | Find type definitions with Telescope |
| `grn` | Rename symbol |
| `gra` | Request code action (Normal or Visual mode) |
| `go` / `gw` | Search document / workspace symbols |
| `<leader>th` | Toggle inlay hints when supported |
| Insert `<C-k>` | Show function signature and highlight the current argument |
| `[d` / `]d` | Previous / next diagnostic |
| `<leader>q` | Put diagnostics into location list |
| `:lopen` / `:lclose` | Open / close location list |
| `:lnext` / `:lprevious` | Next / previous location-list item |
| `:Mason` | Inspect and manage language tools |
| `:checkhealth vim.lsp` | Inspect attached language servers |
| `:lsp restart` / `:lsp stop` | Restart / stop the clients attached to this buffer |
| `:lsp enable {name}` / `:lsp disable {name}` | Turn one server on / off |
| `:LspLog` | Open the LSP client log at its newest entries |
| `:TSC` | Type-check with the project's real, pinned `tsc` (not vtsls's bundled version) |
| `:TSCStop` | Cancel a running `:TSC` |

Configured servers: `vtsls` for TypeScript (default for every project), `eslint` and `oxlint` for linting, plus `html`, `cssls`, and `lua_ls`. `tsc` is also defined but dormant behind `prefer_tsc` in `lua/plugins/lsp.lua` — off after repeated crashes, flip it back on to restore the original per-project TypeScript-version gate.

Neovim 0.12 ships a native `:lsp` command, which makes nvim-lspconfig skip its
whole `plugin/` script — so `:LspInfo`, `:LspEslintFixAll`, and
`:LspOxlintFixAll` do not exist. `:LspLog` is redefined in `lua/plugins/lsp.lua`.

`vtsls` only ever type-checks with its own bundled TypeScript, never the project's pinned version — `:TSC` ([tsc.nvim](https://github.com/dmmulroy/tsc.nvim)) runs the real compiler instead, on demand only.

## Quickfix list

| Command | Action |
| --- | --- |
| `:copen` / `:cclose` | Open / close quickfix list |
| `:cnext` / `:cprevious` | Next / previous quickfix item |
| `:cfirst` / `:clast` | First / last quickfix item |
| `:cdo {command}` | Run command for each quickfix entry |
| `:cfdo {command}` | Run command once per file in quickfix list |

## Visual Multi — multicursor

The permanent Visual Multi prefix is **two backslashes**. Press multi-key sequences quickly because a single `\` is also the Neo-tree mapping prefix.

| Mode | Key | Action |
| --- | --- | --- |
| N/V | `<C-n>` | Select word/subword under cursor; repeat for next occurrence |
| VM | `n` / `N` | Find next / previous occurrence |
| VM | `q` | Skip current occurrence and find the next |
| VM | `Q` | Remove current region |
| N | `<C-Down>` / `<C-Up>` | Add cursors vertically down / up |
| N/V | `\\A` | Select all occurrences |
| N/V | `\\/` | Start a regex-based multicursor selection |
| N | `\\\` | Add a cursor at the current position |
| N | `\\gS` | Reselect regions from the last Visual Multi session |
| V | `\\c` | Create cursors from the selected lines/region |
| V | `\\a` | Add the Visual selection as regions |
| V | `\\f` | Find the Visual selection |
| VM | `R` | Replace text in all regions |
| VM | `<Esc>` | Exit Visual Multi |

Typical workflow: place cursor on a word → `<C-n>` repeatedly → press `c` or `R` → type replacement → `<Esc>`.

## Mini text objects and surrounds

| Key | Action |
| --- | --- |
| `aa` / `ii` | Next “around” / “inside” text object |
| `gsa{motion}{char}` | Add surroundings, for example `gsaiw)` |
| Visual `gsa{char}` | Surround selected text |
| `gsd{char}` | Delete surrounding character, for example `gsd"` |
| `gsr{old}{new}` | Replace surroundings, for example `gsr)'` |
| `gsf{char}` | Find the surrounding character to the left |
| `gsh{char}` | Highlight a surrounding character |

Append `n` or `l` to `gsd`, `gsr`, `gsf`, or `gsh` to act on the next or previous surrounding, for example `gsdn"`. Mini searches 20 lines for a surrounding (its default; `mini.ai` text objects use 500) and there is no mapping to change that at runtime.

Standard text objects remain useful: `iw`, `aw`, `i"`, `a"`, `i'`, `i(`, `a(`, `i{`, `a{`, `it`, `at`, `ip`, `ap`.

## Completion and snippets

| Insert-mode key | Action |
| --- | --- |
| `<C-l>` | Explicitly show Blink completion |
| `<C-Space>` | Open completion, or docs when already open |
| `<C-n>` / `<C-p>` | Next / previous item |
| `<Down>` / `<Up>` | Next / previous item |
| `<C-y>` | Accept selected completion |
| `<C-e>` | Hide completion |
| `<C-k>` | Toggle signature help |
| `<Tab>` / `<S-Tab>` | Move forward / backward through snippet positions |

## Formatting

| Key or command | Action |
| --- | --- |
| `<leader>f` | Format buffer or Visual selection with Conform |
| `:ConformInfo` | Show formatter status for current buffer |

Formatting is manual: there is no format-on-save, so `<leader>f` is the only way to run Conform.

Lua uses StyLua. JavaScript, JSX, TypeScript, TSX, HTML, CSS, JSON, and JSONC use Prettier. LSP formatting is the fallback.

Trailing whitespace is trimmed automatically on every save, independent of Conform — except in Markdown and diff buffers, where trailing double-spaces are a hard line break.

## Folding

Treesitter calculates folds; files start fully open.

| Key | Action |
| --- | --- |
| `zc` / `zo` | Close / open fold under cursor |
| `za` | Toggle fold under cursor |
| `zM` / `zR` | Close / open all folds |
| `zj` / `zk` | Move to next / previous fold |
| `zC` / `zO` | Close / open folds recursively |
| `zx` | Recompute folds and restore fold view |

## Neo-tree

| Key or command | Action |
| --- | --- |
| `<leader>e` | Toggle Neo-tree and reveal current file |
| `\` | Reveal current file in Neo-tree |
| `\` inside Neo-tree | Close Neo-tree window |
| `:Neotree reveal` | Reveal current file |
| `:Neotree toggle reveal` | Toggle explorer and reveal current file |

## Custom terminals and Git

| Key | Action |
| --- | --- |
| `<leader>tt` | Toggle managed terminal split |
| `<leader>tf` | Focus managed terminal split without toggling it closed |
| `<leader>tn` | Create another terminal |
| `<leader>t]` / `<leader>t[` | Next / previous managed terminal |
| `<leader>tc` | Close current managed terminal; last one is protected |
| `<leader>gg` | Open Lazygit in floating terminal |
| Terminal-Normal `i` | Start typing in the terminal |
| Terminal `<Esc><Esc>` | Leave Terminal mode |

Managed terminals open in Terminal-Normal mode, so terminal switching and window navigation work immediately. Press `i` to type. Shell selection lives in `lua/config/shell.lua`: `bash`, `cmd`, or `powershell`.

## External shell commands and filters

Examples below assume the default Git Bash profile. For Command Prompt use commands such as `dir`; for PowerShell use commands such as `Get-ChildItem`.

| Command | Action |
| --- | --- |
| `:!ls` | Run `ls` and display output |
| `:.!ls` | Replace current line with `ls` output |
| `:read !ls` | Insert `ls` output below current line |
| `:%!sort` | Send whole buffer through `sort` and replace it with output |
| `:'<,'>!sort` | Filter Visual selection through `sort` |
| `:w !command` | Send entire buffer to command without replacing buffer |
| `:set shell? shellcmdflag?` | Show active shell and execution flag |

The `.` in `:.!command` is the current-line range. `%` means the entire file, and `'<,'>` is the last Visual selection.

## Plugin and maintenance commands

| Command | Action |
| --- | --- |
| `:lua vim.pack.update(nil, { offline = true })` | Inspect plugin state and pending updates |
| `:lua vim.pack.update()` | Fetch and update plugins |
| `:TSUpdate` | Update Treesitter parsers |
| `:Telescope keymaps` | Search active keymaps |
| `:checkhealth` | Run Neovim/plugin health checks |
| `:messages` | Review recent notifications and errors |
| `:source $MYVIMRC` | Source entry point; restart if a required module is cached |

## Useful help

| Command | Topic |
| --- | --- |
| `:help {topic}` | Open any help topic |
| `:help index` | Built-in command index |
| `:help motion.txt` | Movement |
| `:help change.txt` | Editing, registers, and substitutions |
| `:help registers` | Register behavior |
| `:help complex-repeat` | Macros |
| `:help folding` | Fold commands |
| `:help vm-mappings` | Visual Multi mappings |
| `<leader>sh` | Search help interactively with Telescope |
