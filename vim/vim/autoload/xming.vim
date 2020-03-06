" Move current tab into the specified direction.
" @param direction -1 for left, 1 for right.
function! xming#tabmove(direction) abort
  " get number of tab pages.
  let n = tabpagenr("$")
  let l:index = tabpagenr()
  if a:direction < 0
    let l:index = l:index - 2
    if l:index < 0
      let l:index = n
    endif
  else
    let l:index = l:index + 1
    if l:index > n
      let l:index = 0
    endif
  endif
  " move tab page.
  execute "tabmove " . l:index
endfunction
