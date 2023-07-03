let s:entries = [
      \ { 'code': '%%', 'description': "A literal '%' character" },
      \ { 'code': '%A', 'description': "Weekday as locale's full name" },
      \ { 'code': '%B', 'description': "Month as locale's full name" },
      \ { 'code': '%C', 'description': "Century number (year/100) as a 2-digit number" },
      \ { 'code': '%D', 'description': "Full date in US style, equivalent to %m/%d/%y" },
      \ { 'code': '%F', 'description': "Full date in ISO 8601 style, equivalent to %Y-%m-%d" },
      \ { 'code': '%G', 'description': "ISO 8601 week-based full year (with century) as a decimal number" },
      \ { 'code': '%H', 'description': "Hour, 24-hour clock" },
      \ { 'code': '%I', 'description': "Hour, 12-hour clock" },
      \ { 'code': '%M', 'description': "Minute as a zero-padded decimal number" },
      \ { 'code': '%P', 'description': "Locale's equivalent of either am or pm" },
      \ { 'code': '%R', 'description': "Time, 24-hour clock, equivalent to %H:%M" },
      \ { 'code': '%S', 'description': "Second as a zero-padded decimal number" },
      \ { 'code': '%T', 'description': "Time with seconds, 24-hour clock, equivalent to %H:%M:%S" },
      \ { 'code': '%U', 'description': "Week number of the year (Sunday as the start of the week)" },
      \ { 'code': '%V', 'description': "ISO 8601 week number" },
      \ { 'code': '%W', 'description': "Week number of the year (Monday as the start of the week)" },
      \ { 'code': '%X', 'description': "Locale's appropriate time representation" },
      \ { 'code': '%Y', 'description': "Full year (with century) as a decimal number" },
      \ { 'code': '%Z', 'description': "Time zone name" },
      \ { 'code': '%a', 'description': "Weekday as locale's abbreviated name" },
      \ { 'code': '%b', 'description': "Month as locale's abbreviated name" },
      \ { 'code': '%c', 'description': "Locale's appropriate date and time representation" },
      \ { 'code': '%d', 'description': "Day of the month as a zero-padded decimal number" },
      \ { 'code': '%f', 'description': "Microsecond as a decimal number" },
      \ { 'code': '%g', 'description': "ISO 8601 week-based year without century" },
      \ { 'code': '%j', 'description': "Day of the year as a zero-padded decimal number" },
      \ { 'code': '%m', 'description': "Month as a zero-padded decimal number" },
      \ { 'code': '%p', 'description': "Locale's equivalent of either AM or PM" },
      \ { 'code': '%r', 'description': "Time with seconds and AM/PM, equivalent to %I:%M:%S %p" },
      \ { 'code': '%s', 'description': "Unix timestamp, the number of seconds since the Epoch" },
      \ { 'code': '%u', 'description': "Weekday as a decimal number, where 1 is Monday and 7 is Sunday" },
      \ { 'code': '%w', 'description': "Weekday as a decimal number, where 0 is Sunday and 6 is Saturday" },
      \ { 'code': '%x', 'description': "Locale's appropriate date representation" },
      \ { 'code': '%y', 'description': "Year without century as a zero-padded decimal number" },
      \ { 'code': '%z', 'description': "UTC offset in the form ±HHMM[SS[.ffffff]]" },
      \ ]

let s:by_code = {}
for entry in s:entries
  let s:by_code[entry.code] = entry.description
endfor

let s:popup_window = -1

function! strftime#Complete(findstart, base)
  if a:findstart
    " locate the start of the timestamp
    let [_, start_col] = searchpos('%[-_^]\=\%(\w\|\s\)*', 'bWn', line('.'))
    if start_col <= 1
      return -3 " cancel completion
    else
      return start_col - 1
    endif
  else
    let [prefix, input] = s:ExtractPrefix(a:base)
    let results = []

    if input == ''
      let matches = sort(s:entries, function('s:CompareCodes'))
    else
      let matches = matchfuzzy(s:entries, input, { 'key': 'description' })
    endif

    for entry in matches
      let [code, description] = s:ApplyPrefix(prefix, entry.code, entry.description)
      let description ..= ' (' .. strftime(code) .. ')'

      call add(results, { 'word': code, 'menu': description })
    endfor

    return results
  endif
endfunction

function! strftime#Popup() abort
  " find the start of a string on the line
  let [_, start_col] = searchpos('[''"]', 'bWcn', line('.'))
  if start_col <= 0
    return
  endif

  let line = getline('.')
  let quote = line[start_col - 1]

  if quote == "'"
    let string_contents = s:GetMotion("vi'")
  elseif quote == '"'
    let string_contents = s:GetMotion('vi"')
  else
    return
  endif

  if string_contents == ''
    let string_contents = s:GetMotion('T'.quote.'vg_')
  endif

  let popup_lines = []
  let [special_symbol, _, end_index]  = matchstrpos(string_contents, '^%\(%\|[-_^]\=\w\)')
  let [prefix, code] = s:ExtractPrefix(special_symbol)

  while special_symbol != ''
    if has_key(s:by_code, '%'.code)
      let [code, description] = s:ApplyPrefix(prefix, '%'.code, s:by_code['%'.code])
      call add(popup_lines, code .. "\t" .. description)
    else
      call add(popup_lines, special_symbol .. "\t" .. "[Unknown]")
    endif

    let [special_symbol, _, end_index] =
          \ matchstrpos(string_contents, '^%\(%\|[-_^]\=\w\)', end_index + 1)
    let [prefix, code] = s:ExtractPrefix(special_symbol)
  endwhile

  if len(popup_lines) > 0
    if s:popup_window >= 0
      call popup_close(s:popup_window)
    endif

    let popup_lines = extend([strftime(string_contents), ''], popup_lines)
    let s:popup_window = popup_atcursor(popup_lines, { 'border': [] })
  endif
endfunction

function s:ExtractPrefix(base) abort
  let prefix = matchstr(a:base, '^%\zs[-_^]')
  let input = substitute(a:base, '^%[-_^]\=', '', '')

  return [prefix, input]
endfunction

function! s:ApplyPrefix(prefix, code, description) abort
  let prefix      = a:prefix
  let code        = a:code
  let description = a:description

  if prefix == '-'
    let code        = substitute(code, '^%', '%-', '')
    let description = substitute(description, ' zero-padded ', ' ', 'g')
  elseif prefix == '_'
    let code        = substitute(code, '^%', '%_', '')
    let description = substitute(description, ' zero-padded ', ' blank-padded ', 'g')
  elseif prefix == '^'
    let code = substitute(code, '^%', '%^', '')
  endif

  return [code, description]
endfunction

function! s:GetMotion(motion) abort
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

function! s:CompareCodes(left, right) abort
  let left_code = a:left.code
  let right_code = a:right.code

  if left_code ==# right_code
    return 0
  elseif left_code ># right_code
    return 1
  else
    return -1
  endif
endfunction
