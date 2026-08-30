# Neovim configuration

Personal Neovim configuration for Windows, organized into core settings, plugin configuration, and custom terminal support. It uses Neovim's built-in `vim.pack` package manager and sets both the global and local leader to `Space`.

See [CHEATSHEET.md](CHEATSHEET.md) for the command and key reference.

## Requirements

- Neovim 0.12 or newer
- Git
- [ripgrep](https://github.com/BurntSushi/ripgrep) for Telescope live grep
- [lazygit](https://github.com/jesseduffield/lazygit) for the floating Git interface
- `stylua` and `prettier` on `PATH` for configured formatting
- Git Bash at `C:/Users/petar.iva/AppData/Local/Programs/Git/bin/bash.exe` for custom terminals
- Optional: `make` for Telescope's native FZF extension and supported plugin build hooks

## Configuration layout

| Path | Responsibility |
| --- | --- |
| `init.lua` | Loads every module in dependency order |
| `lua/config/options.lua` | Leaders, globals, and editor options |
| `lua/config/shell.lua` | Shared Bash, Command Prompt, and PowerShell profiles |
| `lua/config/keymaps.lua` | Global mappings and diagnostics |
| `lua/config/autocmds.lua` | General and terminal highlight autocmds |
| `lua/config/pack.lua` | `vim.pack` build hooks and GitHub URL helper |
| `lua/plugins/ui.lua` | Theme, Bufferline, statusline, Gitsigns, Which-key, and Mini |
| `lua/plugins/telescope.lua` | Search, picker, buffer, and LSP picker mappings |
| `lua/plugins/lsp.lua` | LSP attachment, servers, and Mason |
| `lua/plugins/formatting.lua` | Conform and format-on-save |
| `lua/plugins/completion.lua` | Blink completion and LuaSnip |
| `lua/plugins/treesitter.lua` | Parser installation and attachment |
| `lua/plugins/neo-tree.lua` | File explorer setup |
| `lua/custom/terminal.lua` | Persistent split terminals and floating commands |

## Key notation

| Notation | Meaning |
| --- | --- |
| `<leader>` | `Space` |
| `<C-x>` | Hold `Ctrl` and press `x` |
| `<A-x>` | Hold `Alt` and press `x` |
| `<S-x>` | Hold `Shift` and press `x` |
| Normal | Normal mode |
| Visual | Visual or selection mode |
| Insert | Insert mode |
| Terminal | Terminal-input mode |

## Shell selection

The shell used by `:!`, filters such as `:.!command`, and custom terminal windows is selected in `lua/config/shell.lua`:

```lua
M.selected = 'bash'
```

Change that value to one of the configured profiles:

| Value | Shell | Example command |
| --- | --- | --- |
| `'bash'` | Git Bash | `:!ls` |
| `'cmd'` | Command Prompt | `:!dir` |
| `'powershell'` | Windows PowerShell | `:!Get-ChildItem` |

Each profile sets its executable, command flag, quoting, redirection, and terminal arguments together. Restart Neovim after changing the selected profile.

Useful forms:

- `:!command` runs a command and displays its output.
- `:.!command` replaces the current line with the command output.
- `:read !command` inserts the command output below the current line.
- `:%!command` filters the entire buffer through the command.
- `:set shell? shellcmdflag?` displays the active executable and command flag.

## General editing and windows

| Mode | Key | Action |
| --- | --- | --- |
| Normal | `<S-h>` | Open the previous buffer |
| Normal | `<S-l>` | Open the next buffer |
| Normal | `<leader>v` | Create a vertical split |
| Normal | `<leader>h/j/k/l` | Focus the window to the left/down/up/right |
| Normal | `<C-h/j/k/l>` | Focus the window to the left/down/up/right |
| Normal | `<A-j>` | Move the current line down and reindent it |
| Normal | `<A-k>` | Move the current line up and reindent it |
| Visual | `<A-j>` | Move the selected lines down and preserve the selection |
| Visual | `<A-k>` | Move the selected lines up and preserve the selection |
| Normal | `<Esc>` | Clear search highlighting |
| Visual | `s` | Replace the selection, using Vim's `c` operation |

## Buffers

| Key | Action |
| --- | --- |
| `<leader>bn` | Open the next buffer |
| `<leader>bp` | Open the previous buffer |
| `<leader>bd` | Delete the current buffer |
| `<leader>bb` | Create a new empty buffer |
| `<leader>sb` | Search open buffers with Telescope |

## File explorer

| Key | Action |
| --- | --- |
| `\` | Reveal the current file in Neo-tree |
| `\` inside Neo-tree | Close the Neo-tree window |
| `<leader>e` | Toggle Neo-tree and reveal the current file |

Useful commands:

- `:Neotree reveal` reveals the current file.
- `:Neotree toggle reveal` toggles the explorer while revealing the current file.

## Search and Telescope

| Mode | Key | Action |
| --- | --- | --- |
| Normal | `<leader><leader>` | Find files |
| Normal | `<leader>sh` | Search Neovim help tags |
| Normal | `<leader>sk` | Search active keymaps |
| Normal | `<leader>sf` | Find files |
| Normal | `<leader>ss` | Select a Telescope picker |
| Normal/Visual | `<leader>sw` | Search for the word under the cursor or selection |
| Normal | `<leader>sg` | Search project text with live grep |
| Normal | `<leader>sd` | Search diagnostics |
| Normal | `<leader>sr` | Resume the previous Telescope picker |
| Normal | `<leader>s.` | Search recently opened files |
| Normal | `<leader>sc` | Search available commands |
| Normal | `<leader>sn` | Search files in the Neovim configuration |
| Normal | `<leader>/` | Fuzzy-search the current buffer in a dropdown |
| Normal | `<leader>s/` | Live-grep only the currently open files |

Use `:Telescope keymaps` to inspect all active mappings or `:Telescope builtin` to choose any available picker.

## Diagnostics and LSP

The LSP mappings below are buffer-local and appear only after a language server attaches.

| Mode | Key | Action |
| --- | --- | --- |
| Normal | `<leader>q` | Put diagnostics into the location list |
| Normal | `grn` | Rename the symbol under the cursor |
| Normal/Visual | `gra` | Request a code action |
| Normal | `grr` | Find references with Telescope |
| Normal | `gri` | Find implementations with Telescope |
| Normal | `grd` | Find definitions with Telescope |
| Normal | `grD` | Go to the declaration with LSP |
| Normal | `grt` | Find type definitions with Telescope |
| Normal | `go` | Search document symbols |
| Normal | `gw` | Search workspace symbols |
| Normal | `<leader>th` | Toggle inlay hints when the server-support check succeeds |

Configured language servers:

- TypeScript (`ts_ls`)
- HTML (`html`)
- CSS (`cssls`)
- Lua (`lua_ls`)

Use `:Mason` to inspect installed language tooling. Diagnostic jumps use Neovim's normal diagnostic mappings; the configuration opens a rounded diagnostic float after a jump.

## Formatting

| Mode | Key | Action |
| --- | --- | --- |
| Normal/Visual | `<leader>f` | Format the buffer or selection synchronously with Conform |

Format-on-save is enabled for Lua, JavaScript, JSX, TypeScript, TSX, HTML, CSS, JSON, and JSONC. Lua uses `stylua`; the other configured filetypes use `prettier`. LSP formatting is used as a fallback.

Use `:ConformInfo` to see the formatter selected for the current buffer and whether its executable is available.

## Completion and snippets

| Mode | Key | Action |
| --- | --- | --- |
| Insert | `<C-l>` | Explicitly show the Blink completion menu |
| Insert | `<C-y>` | Accept the selected completion using Blink's `default` preset |
| Insert | `<C-Space>` | Open completion, or documentation when completion is already open |
| Insert | `<C-n>` / `<C-p>` | Select the next or previous completion item |
| Insert | `<Down>` / `<Up>` | Select the next or previous completion item |
| Insert | `<C-e>` | Hide completion |
| Insert | `<C-k>` | Toggle signature help |
| Insert/Snippet | `<Tab>` / `<S-Tab>` | Move forward or backward through snippet positions |

Completion sources are LSP, filesystem paths, and LuaSnip snippets. Documentation does not open automatically, while signature help is enabled.

## Mini text objects and surrounds

| Mode | Key | Action |
| --- | --- | --- |
| Operator/Visual | `aa` | Use the next “around” text object |
| Operator/Visual | `ii` | Use the next “inside” text object |
| Normal/Visual | `gsa` | Add surrounding characters |
| Normal | `gsd` | Delete surrounding characters |
| Normal | `gsf` | Find a surrounding character |
| Normal | `gsh` | Highlight surrounding characters |
| Normal | `gsr` | Replace surrounding characters |
| Normal | `gsn` | Change the number of lines searched for surroundings |

`vim-visual-multi` is installed with its upstream default mappings. Use `:help vm-mappings` for its complete multi-cursor key reference.

## Folding

Folds are calculated from Treesitter syntax and start open, so files remain fully visible until a fold command is used.

| Mode | Key | Action |
| --- | --- | --- |
| Normal | `zc` | Close the fold under the cursor |
| Normal | `zo` | Open the fold under the cursor |
| Normal | `za` | Toggle the fold under the cursor |
| Normal | `zM` | Close all folds |
| Normal | `zR` | Open all folds |
| Normal | `zj` | Move to the next fold |
| Normal | `zk` | Move to the previous fold |

## Custom terminals and Git

| Mode | Key | Action |
| --- | --- | --- |
| Normal | `<leader>tt` | Show or hide the terminal split; creates one when necessary |
| Normal | `<leader>tn` | Create a new terminal |
| Normal | `<leader>t]` | Show the next managed terminal |
| Normal | `<leader>t[` | Show the previous managed terminal |
| Normal | `<leader>tc` | Close the current managed terminal; the last terminal is protected |
| Normal | `<leader>gg` | Open `lazygit` in a centered floating terminal |
| Terminal | `<Esc><Esc>` | Leave terminal-input mode and return to Normal mode |

Managed terminals open in a 12-line bottom split, remain alive when hidden, and use Git Bash as an interactive login shell. Floating commands close their window automatically when the command exits.

## Plugin and maintenance commands

| Command | Purpose |
| --- | --- |
| `:lua vim.pack.update(nil, { offline = true })` | Inspect plugin state and pending updates without fetching |
| `:lua vim.pack.update()` | Fetch and update managed plugins |
| `:Mason` | Inspect and manage external LSP tools |
| `:TSUpdate` | Update installed Treesitter parsers |
| `:Telescope keymaps` | Search all active keymaps |
| `:ConformInfo` | Inspect formatting for the current buffer |
| `:checkhealth` | Run Neovim and plugin health checks |
| `:messages` | Review recent notifications and errors |

Which-key opens immediately after a recognized prefix and groups search under `<leader>s`, terminal actions under `<leader>t`, and LSP actions under `gr`.

## Known preserved issues

These behaviors were present before the structural refactor and have intentionally not been changed:

- The Treesitter build hook invokes lowercase `tsupdate`; the interactive command is `TSUpdate`.
- Several lowercase LSP protocol/configuration fields and lowercase Neovim severity constants may prevent their intended behavior.
- When Nerd Font support is enabled, the UI setup calls nonexistent global `miniicons` instead of `MiniIcons`.

Those issues should be changed only as a deliberate behavioral follow-up.
