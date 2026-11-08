" :QfSave / :QfLoad: the quickfix list to a file and back, with its title,
" its context and its entries' user_data, so a plugin's list works as it did.
" They work as vim-draft's :DraftSave: a name, a path, a directory, or
" nothing for the file the list was last saved to or loaded from.

let s:version = 1

" The file each quickfix list (by id) was last saved to or loaded from
let s:files = {}

function! s:has_place() abort
  return !empty(globpath(&runtimepath, 'autoload/roumail_place.vim', 1))
endfunction

" What needs vim-place says so when it isn't installed
function! s:requires(what) abort
  if s:has_place()
    return 1
  endif
  echohl ErrorMsg
  echomsg 'qf-tools: ' . a:what . ' needs vim-place (with vim-fugitive), which is not installed'
  echohl None
  return 0
endfunction

" A path has a / or starts with ~ or .; anything else is a name, kept where
" vim-place keeps plugins' files
function! s:is_path(arg) abort
  return a:arg =~# '/' || a:arg =~# '^[~.]'
endfunction

function! s:save_dir() abort
  return roumail_place#dir('qf-tools')
endfunction

" Named for the time, so they sort
function! s:new_file(dir) abort
  let l:base = a:dir . '/' . strftime('%Y%m%d-%H%M%S')
  let l:path = l:base . '.json'
  let l:n = 1
  while filereadable(l:path)
    let l:n += 1
    let l:path = l:base . '-' . l:n . '.json'
  endwhile
  return l:path
endfunction

" The saves here, newest first
function! s:saves() abort
  return sort(glob(s:save_dir() . '/*.json', 1, 1), {a, b -> getftime(b) - getftime(a)})
endfunction

" The directory a save's entries are relative to: the work tree, for a file
" where vim-place keeps plugins' files; '' (absolute paths) elsewhere
function! s:root(file) abort
  if !s:has_place()
    return ''
  endif
  return stridx(a:file, s:save_dir() . '/') == 0 ? roumail_place#get().dir : ''
endfunction

function! s:shown(file) abort
  return fnamemodify(a:file, ':~')
endfunction

" value if it can be written as JSON, else v:null
function! s:jsonable(value) abort
  try
    call json_encode(a:value)
    return a:value
  catch
    return v:null
  endtry
endfunction

" The file to write: the given path, a new file in the given directory, a
" name's file, else the file the list was last saved to or loaded from, else
" a new one in the save directory; '' after an error
function! s:target(id, arg) abort
  if empty(a:arg)
    if has_key(s:files, a:id)
      return s:files[a:id]
    endif
    return s:requires(':QfSave without a path') ? s:new_file(s:save_dir()) : ''
  elseif !s:is_path(a:arg)
    return s:requires(':QfSave of a name') ? s:save_dir() . '/' . a:arg . '.json' : ''
  endif
  " :p ends an existing directory with /
  let l:path = fnamemodify(expand(a:arg), ':p')
  return l:path =~# '/$' ? s:new_file(substitute(l:path, '/\+$', '', '')) : l:path
endfunction

function! qf_tools#save#save(bang, arg) abort
  let l:list = getqflist({'id': 0, 'title': 1, 'context': 0, 'items': 1})
  let l:file = s:target(l:list.id, a:arg)
  if empty(l:file)
    return
  endif
  " A name is the list's to save again; a path you gave, only with !
  if s:is_path(a:arg) && filereadable(l:file) && !a:bang && l:file !=# get(s:files, l:list.id, '')
    echoerr 'QfSave: ' . s:shown(l:file) . ' exists (add ! to overwrite)'
  endif
  let l:root = s:root(l:file)
  let l:dropped = 0
  let l:items = []
  for l:item in l:list.items
    let l:entry = copy(l:item)
    call remove(l:entry, 'bufnr')
    if l:item.bufnr
      " A plugin's buffer (fugitive://) keeps its name: :p leaves it be
      let l:name = fnamemodify(bufname(l:item.bufnr), ':p')
      if !empty(l:root) && stridx(l:name, l:root . '/') == 0
        let l:name = strpart(l:name, len(l:root) + 1)
      endif
      let l:entry.filename = l:name
    endif
    if has_key(l:entry, 'user_data')
      let l:data = s:jsonable(l:entry.user_data)
      if l:data is v:null && l:entry.user_data isnot v:null && !empty(l:entry.user_data)
        let l:dropped += 1
      endif
      let l:entry.user_data = l:data is v:null ? '' : l:data
    endif
    call add(l:items, l:entry)
  endfor
  let l:context = s:jsonable(l:list.context)
  if l:context is v:null && !empty(l:list.context)
    let l:dropped += 1
  endif
  call mkdir(fnamemodify(l:file, ':h'), 'p')
  " A failed write is an error before the file is taken: the list stays as it
  " was
  call writefile([json_encode({'qf_tools': s:version, 'title': l:list.title,
        \ 'context': l:context is v:null ? '' : l:context, 'items': l:items})], l:file)
  let s:files[l:list.id] = l:file
  echo 'QfSave: wrote ' . s:shown(l:file) . ' (' . len(l:items) . ' entries'
        \ . (l:dropped ? ', ' . l:dropped . ' context(s) not JSON, left out' : '') . ')'
endfunction

" The given path or name's file, else the newest save here
function! qf_tools#save#load(arg) abort
  if empty(a:arg)
    if !s:requires(':QfLoad without a path')
      return
    endif
    let l:saves = s:saves()
    if empty(l:saves)
      echoerr 'QfLoad: nothing saved in ' . s:shown(s:save_dir())
    endif
    let l:file = l:saves[0]
  elseif s:is_path(a:arg)
    let l:file = fnamemodify(expand(a:arg), ':p')
    if !filereadable(l:file)
      echoerr 'QfLoad: no ' . s:shown(l:file)
    endif
  else
    if !s:requires(':QfLoad of a name')
      return
    endif
    let l:file = s:save_dir() . '/' . a:arg . '.json'
    if !filereadable(l:file)
      echoerr 'QfLoad: no saved list ' . a:arg
    endif
  endif
  try
    let l:saved = json_decode(join(readfile(l:file), "\n"))
  catch
    let l:saved = {}
  endtry
  if type(l:saved) != v:t_dict || !has_key(l:saved, 'qf_tools')
    echoerr 'QfLoad: ' . s:shown(l:file) . ' is not a list :QfSave wrote'
  endif
  let l:root = s:root(l:file)
  let l:items = l:saved.items
  for l:item in l:items
    if has_key(l:item, 'filename') && !empty(l:root)
          \ && l:item.filename !~# '^/\|^\a\+://'
      let l:item.filename = l:root . '/' . l:item.filename
    endif
  endfor
  " A new list, so :colder goes back to the one before it
  call setqflist([], ' ', {'title': l:saved.title, 'context': l:saved.context, 'items': l:items})
  let s:files[getqflist({'id': 0}).id] = l:file
  copen
  echo 'QfLoad: read ' . s:shown(l:file) . ' (' . len(l:items) . ' entries)'
endfunction

" The saves here, newest first, then files
function! qf_tools#save#complete(lead, cmdline, pos) abort
  if s:is_path(a:lead) || !s:has_place()
    return getcompletion(a:lead, 'file')
  endif
  let l:names = map(s:saves(), 'fnamemodify(v:val, ":t:r")')
  return filter(l:names, 'stridx(v:val, a:lead) == 0')
endfunction
