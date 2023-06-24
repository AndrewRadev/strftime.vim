" Taken from https://strftime.org/
"
" Note:
"   -    -> no leading zeroes
"   _    -> blank-padded
"   ^    -> uppercase
"   E, O -> alternative format
"
" Check: https://en.cppreference.com/w/cpp/chrono/c/strftime
" Check: https://linux.die.net/man/3/strftime
"
let s:strftime_codes = {
      \ '%%': "A literal '%' character",
      \ '%A': "Weekday as locale's full name",
      \ '%B': "Month as locale's full name",
      \ '%C': "Century number (year/100) as a 2-digit number",
      \ '%D': "Full date in US style, equivalent to %m/%d/%y",
      \ '%F': "Full date in ISO 8601 style, equivalent to %Y-%m-%d",
      \ '%G': "ISO 8601 week-based full year (with century) as a decimal number",
      \ '%H': "Hour, 24-hour clock",
      \ '%I': "Hour, 12-hour clock",
      \ '%M': "Minute as a zero-padded decimal number",
      \ '%P': "Locale's equivalent of either am or pm",
      \ '%R': "Time, 24-hour clock, equivalent to %H:%M",
      \ '%S': "Second as a zero-padded decimal number",
      \ '%T': "Time with seconds, 24-hour clock, equivalent to %H:%M:%S",
      \ '%U': "Week number of the year (Sunday as the start of the week)",
      \ '%V': "ISO 8601 week number",
      \ '%W': "Week number of the year (Monday as the start of the week)",
      \ '%X': "Locale's appropriate time representation",
      \ '%Y': "Full year (with century) as a decimal number",
      \ '%Z': "Time zone name",
      \ '%a': "Weekday as locale's abbreviated name",
      \ '%b': "Month as locale's abbreviated name",
      \ '%c': "Locale's appropriate date and time representation",
      \ '%d': "Day of the month as a zero-padded decimal number",
      \ '%f': "Microsecond as a decimal number",
      \ '%g': "ISO 8601 week-based year without century",
      \ '%j': "Day of the year as a zero-padded decimal number",
      \ '%m': "Month as a zero-padded decimal number",
      \ '%p': "Locale's equivalent of either AM or PM",
      \ '%r': "Time with seconds and AM/PM, equivalent to %I:%M:%S %p",
      \ '%s': "Unix timestamp, the number of seconds since the Epoch",
      \ '%u': "Weekday as a decimal number, where 1 is Monday and 7 is Sunday",
      \ '%w': "Weekday as a decimal number, where 0 is Sunday and 6 is Saturday",
      \ '%x': "Locale's appropriate date representation",
      \ '%y': "Year without century as a zero-padded decimal number",
      \ '%z': "UTC offset in the form ±HHMM[SS[.ffffff]]",
      \ }
let s:popup_window = -1

function! strftime#Complete(findstart, base)
  if a:findstart
    " locate the start of the timestamp
    let [_, start_col] = searchpos('%\%(\w\|\s\)*', 'bWn', line('.'))
    if start_col <= 1
      return -3 " cancel completion
    else
      return start_col - 1
    endif
  else
    let input = substitute(a:base, '^%', '', '')
    let results = []

    for [code, description] in items(s:strftime_codes)
      if input == '' || len(matchfuzzy([description], input)) > 0
        let description ..= ' (' .. strftime(code) .. ')'
        call add(results, { 'word': code, 'menu': description })
      endif
    endfor

    return sort(results, function('s:CompareWords'))
  endif
endfunction

function! strftime#Popup()
  " find the start of a string on the line
  let [_, start_col] = searchpos('[''"]', 'bWcn', line('.'))
  if start_col <= 0
    return
  endif

  let line = getline('.')

  if line[start_col - 1] == "'"
    let string_contents = s:GetMotion("vi'")
  elseif line[start_col - 1] == '"'
    let string_contents = s:GetMotion('vi"')
  else
    return
  endif

  let popup_lines = []
  let [special_symbol, _, end_index]  = matchstrpos(string_contents, '^%\(%\|-\?\w\)')

  while special_symbol != ''
    if has_key(s:strftime_codes, special_symbol)
      call add(popup_lines, special_symbol .. "\t" .. s:strftime_codes[special_symbol])
    else
      call add(popup_lines, special_symbol .. "\t" .. "[Unknown]")
    endif

    let [special_symbol, _, end_index] =
          \ matchstrpos(string_contents, '^%\(%\|-\?\w\)', end_index + 1)
  endwhile

  if len(popup_lines) > 0
    if s:popup_window >= 0
      call popup_close(s:popup_window)
    endif

    let popup_lines = extend([strftime(string_contents), ''], popup_lines)
    let s:popup_window = popup_atcursor(popup_lines, { 'border': [] })
  endif
endfunction

function! s:GetMotion(motion)
  let saved_view = winsaveview()

  let saved_selection = &selection
  let &selection = "inclusive"
  let saved_register_text = getreg('z', 1)
  let saved_register_type = getregtype('z')
  let saved_opening_visual = getpos("'<")
  let saved_closing_visual = getpos("'>")

  let @z = ''
  exec 'silent noautocmd normal! '.a:motion.'"zy'
  let text = @z

  if text == ''
    " nothing got selected, so we might still be in visual mode
    exe "normal! \<esc>"
  endif

  call setreg('z', saved_register_text, saved_register_type)
  call setpos("'<", saved_opening_visual)
  call setpos("'>", saved_closing_visual)
  let &selection = saved_selection

  call winrestview(saved_view)

  return text
endfunction

function! s:CompareWords(left, right) abort
  let left_word = a:left.word
  let right_word = a:right.word

  if left_word ==# right_word
    return 0
  elseif left_word ># right_word
    return 1
  else
    return -1
  endif
endfunction
