" qf-tools: toggle the quickfix window, delete / restore entries from inside
" a list window, and save the quickfix list to load it back.

command! QfToggle call qf_tools#toggle()
" The quickfix list to a file and back, as vim-place's save contract has it:
" a name, a path, a directory, or nothing for the file it was last saved to
" or loaded from (:QfLoad: the newest save)
command! -bang -nargs=? -complete=customlist,qf_tools#save#complete QfSave
      \ call qf_tools#save#save(<bang>0, <q-args>)
command! -nargs=? -complete=customlist,qf_tools#save#complete QfLoad
      \ call qf_tools#save#load(<q-args>)

" Toggle the quickfix window: bind it, e.g. nmap yoq <Plug>(qf-tools-toggle).
" dd / visual d / u in list windows: ftplugin/qf/qf_tools.vim
nnoremap <Plug>(qf-tools-toggle) <Cmd>call qf_tools#toggle()<CR>
