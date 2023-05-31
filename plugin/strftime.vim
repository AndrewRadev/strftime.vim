if exists('g:loaded_strftime') || &cp
  finish
endif

let g:loaded_strftime = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

command! StrftimePopup call strftime#Popup()

inoremap <expr> <Plug>StrftimeComplete <SID>CompleteOnce()

function s:CompleteOnce()
  let b:saved_completefunc = &completefunc
  set completefunc=strftime#Completefunc

  autocmd CompleteDone * ++once let &completefunc = b:saved_completefunc
  autocmd CompleteDone * ++once unlet b:saved_completefunc

  return "\<c-x>\<c-u>"
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
