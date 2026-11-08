# qf-tools

Toggle the quickfix window, remove entries from quickfix and location lists,
and save a quickfix list to load it back later.

**Vim or Neovim:** tested on Vim 9.1 and newer. It's plain Vimscript, so it may
work on Neovim, but that's untested.

## Install

```vim
Plug 'vimoured/qf-tools'
```

Saving by name, or with no argument, also needs
[vim-place](https://github.com/vimoured/vim-place) and
[vim-fugitive](https://github.com/tpope/vim-fugitive):

```vim
Plug 'tpope/vim-fugitive'
Plug 'vimoured/vim-place'
Plug 'vimoured/qf-tools'
```

## Use

Bind the toggle yourself:

```vim
nmap yoq <Plug>(qf-tools-toggle)
```

| Command | What it does |
| --- | --- |
| `:QfToggle` | Open the quickfix window, or close it if it's open. |
| `:QfSave[!] [name\|path\|dir/]` | Write the quickfix list to a file. With no argument, write to the file it was last saved to or loaded from, else a new one. `!` overwrites another file at that path. |
| `:QfLoad [name\|path]` | Load a saved list as a new quickfix list; with no argument, the newest save. `<Tab>` completes names. |

In a quickfix or location list window:

| Key | What it does |
| --- | --- |
| `dd` | Remove the entry under the cursor; `3dd` removes three. |
| `d` (visual) | Remove the selected entries. |
| `u` | Put back what was last removed; with nothing to put back, go to the older list. |

After those keys change a list, `User QfToolsChanged` fires with the list
window current, for other plugins to follow.

## Tests

The specs in [vim-suite](https://github.com/vimoured/vim-suite) define what it
does: `test/qf-tools.vim`.
