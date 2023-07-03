if exists('g:loaded_strftime') || &cp
  finish
endif

let g:loaded_strftime = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

inoremap <expr> <Plug>StrftimeComplete <SID>CompleteOnce()
command! StrftimePopup call strftime#Popup()

function s:CompleteOnce()
  if pumvisible()
    return "\<c-n>"
  endif

  if &l:completefunc == 'strftime#Complete'
    return "\<c-x>\<c-u>"
  endif

  let b:saved_completefunc = &completefunc
  setlocal completefunc=strftime#Complete

  autocmd CompleteDone * ++once let &completefunc = b:saved_completefunc
  autocmd CompleteDone * ++once unlet b:saved_completefunc

  return "\<c-x>\<c-u>"
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
