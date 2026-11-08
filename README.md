# qf-tools

Small helpers for the quickfix and location lists.

| Command | `<Plug>` mapping | What it does |
| --- | --- | --- |
| `:QfToggle` | `<Plug>(qf-tools-toggle)` | Open the quickfix window, or close it if one is open (*not yet*: with a location list window open, it takes that for the quickfix window and opens nothing). |
| `:QfSave[!] [name\|path\|dir/]` | | Write the quickfix list to a file: its title, its entries and what a plugin keeps on them, so a list such as pytest.vim's `:PytestTests` works as before once loaded. See [Saving](#saving). |
| `:QfLoad [name\|path]` | | Load a saved list as a new quickfix list, so `:colder` goes back to the one before it: a name, a path, else the newest save. `<Tab>` completes names, newest first. |

| Key | Where | What it does |
| --- | --- | --- |
| `dd` | quickfix / location list window | Remove the entry under the cursor; `3dd` three of them. |
| `d` (visual) | quickfix / location list window | Remove the selected entries. |
| `u` | quickfix / location list window | Put back what the last `dd` or `d` removed. With nothing left to put back, go to the older list (`:colder` / `:lolder`). |

Removing entries edits the list in place, so the 10-list quickfix history
stays as it was.

The toggle is yours to bind, for example:

```vim
nmap yoq <Plug>(qf-tools-toggle)
```

*Not yet* marks a known bug: [vim-suite](https://github.com/vimoured/vim-suite)
asserts the behaviour described (its `test/known-failures.txt`), and the note
goes once it's fixed.

## Saving

`:QfSave` works as [vim-draft](https://github.com/vimoured/vim-draft)'s
`:DraftSave`. To keep a list you pruned with `dd` before a plugin rebuilds
it, `:QfSave` it, and `:QfLoad` it later.

| Argument | Written to |
| --- | --- |
| a name (no `/`, not starting with `~` or `.`) | `<name>.json` in the save directory, saved again each time. |
| a path | That file (`!` to overwrite a file the list wasn't saved to or loaded from). |
| a directory (existing, or ending in `/`) | A new file in it, named for the time. |
| none, saved or loaded before | The file the list was last saved to or loaded from. |
| none | A new file, named for the time, in the save directory. |

The save directory is `qf-tools/` where
[vim-place](https://github.com/roumail/vim-place) keeps plugins' files: the
git directory of the repository (shared by work trees), else, outside one,
for the current directory. Files there keep their entries' paths relative
to the work tree; files elsewhere, absolute. `:QfSave` says what it wrote and
how many entries; what a plugin keeps on a list that can't be written as JSON
(a function) is left out, and it says so. A write that fails is an error and
leaves the list as it was.

## For other plugins

After `dd`, `d` or `u` changes a list, `User QfToolsChanged` fires, with
the list window current, so a plugin can keep track of what was removed
from a list of its own:

```vim
autocmd User QfToolsChanged call MyPluginSync()
```

## Install

The core is qf-tools on its own:

```vim
Plug 'vimoured/qf-tools'
```

That gives you every command and key, with `:QfSave` and `:QfLoad` to a
path or directory you give.

Each row below adds a module on top of the core, and **Needs** is the whole
set of plugins it takes besides the core:

| Needs | Module | Adds |
| --- | --- | --- |
| [vim-place](https://github.com/roumail/vim-place) + [vim-fugitive](https://github.com/tpope/vim-fugitive) | Saves per repository | `:QfSave` and `:QfLoad` of a name, or with no argument, in the save directory (see [Saving](#saving)); without it they say so |

All of it:

```vim
Plug 'tpope/vim-fugitive'
Plug 'roumail/vim-place'
Plug 'vimoured/qf-tools'
```

## Tests

Tested by [vim-suite](https://github.com/vimoured/vim-suite), in
`test/qf-tools.vim`, with the dotfiles and the plugins that use it. Every
pull request runs them.
