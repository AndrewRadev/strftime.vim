if exists('g:loaded_strftime') || &cp
  finish
endif

let g:loaded_strftime = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

command! StrftimePopup call strftime#Popup()

" set completefunc=strftime#Complete

let &cpo = s:keepcpo
unlet s:keepcpo
