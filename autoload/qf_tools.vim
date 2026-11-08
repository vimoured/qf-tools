function! qf_tools#toggle() abort
  if getqflist({'winid': 0}).winid
    cclose
  else
    copen
  endif
endfunction

function! s:IsLoclist() abort
  return getwininfo(win_getid())[0].loclist
endfunction

function! s:GetList(what) abort
  return s:IsLoclist() ? getloclist(0, a:what) : getqflist(a:what)
endfunction

" Replaces the items in place, so deleting doesn't use up the 10-list stack
function! s:SetItems(items) abort
  if s:IsLoclist()
    call setloclist(0, [], 'r', {'items': a:items})
  else
    call setqflist([], 'r', {'items': a:items})
  endif
  if exists('#User#QfToolsChanged')
    doautocmd <nomodeline> User QfToolsChanged
  endif
endfunction

" Deletions as [lnum, items], newest last, so u puts back all a 3dd or a
" visual d took. Reset when the window shows a different list.
function! s:UndoStack() abort
  let l:id = s:GetList({'id': 0}).id
  if get(w:, 'qf_undo_id', -1) != l:id
    let w:qf_undo_id = l:id
    let w:qf_undo = []
  endif
  return w:qf_undo
endfunction

" Removes entries line1-line2 of the list in the window (to its end, at most)
function! qf_tools#delete(line1, line2) abort
  let l:items = s:GetList({'items': 1}).items
  if a:line1 > len(l:items)
    return
  endif
  let l:removed = remove(l:items, a:line1 - 1, min([a:line2, len(l:items)]) - 1)
  call add(s:UndoStack(), [a:line1, l:removed])
  call s:SetItems(l:items)
  call cursor(min([a:line1, len(l:items)]), 1)
endfunction

function! qf_tools#undo() abort
  let l:stack = s:UndoStack()
  if empty(l:stack)
    execute s:IsLoclist() ? 'lolder' : 'colder'
    return
  endif
  let [l:lnum, l:removed] = remove(l:stack, -1)
  let l:items = s:GetList({'items': 1}).items
  call s:SetItems(extend(l:items, l:removed, l:lnum - 1))
  call cursor(l:lnum, 1)
endfunction
