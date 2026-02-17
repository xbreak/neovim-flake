" Indent text object
" Useful for python-like indentation based programming lanugages
" Usage:
" onoremap <silent>ii :<C-u>call text#obj_indent(v:true)<CR>
" onoremap <silent>ai :<C-u>call text#obj_indent(v:false)<CR>
" xnoremap <silent>ii :<C-u>call text#obj_indent(v:true)<CR>
" xnoremap <silent>ai :<C-u>call text#obj_indent(v:false)<CR>
"
" From https://github.com/habamax/.vim/blob/master/autoload/text.vim#L123-L205
func! text#obj_indent(inner)
    if getline('.') =~ '^\s*$'
        let ln_start = s:detect_nearest_line()
        let ln_end = ln_start
    else
        let ln_start = line('.')
        let ln_end = ln_start
    endif

    let indent = indent(ln_start)
    if indent > 0
        while indent(ln_start) >= indent && ln_start > 0
            let ln_start = prevnonblank(ln_start-1)
        endwhile

        while indent(ln_end) >= indent && ln_end <= line('$')
            let ln_end = s:nextnonblank(ln_end+1)
        endwhile
    else
        while indent(ln_start) == 0 && ln_start > 0 && getline(ln_start) !~ '^\s*$'
            let ln_start -= 1
        endwhile
        while indent(ln_start) > 0 && ln_start > 0
            let ln_start = prevnonblank(ln_start-1)
        endwhile
        while indent(ln_start) == 0 && ln_start > 0 && getline(ln_start) !~ '^\s*$'
            let ln_start -= 1
        endwhile

        while indent(ln_end) == 0 && ln_end <= line('$') && getline(ln_end) !~ '^\s*$'
            let ln_end += 1
        endwhile
        while indent(ln_end) > 0 && ln_end <= line('$')
            let ln_end = s:nextnonblank(ln_end+1)
        endwhile
    endif

    if a:inner || indent == 0
        let ln_start = s:nextnonblank(ln_start+1)
    endif

    if a:inner
        let ln_end = prevnonblank(ln_end-1)
    else
        let ln_end = ln_end-1
    endif

    if ln_end < ln_start
        let ln_end = ln_start
    endif

    exe ln_end
    normal! V
    exe ln_start
endfunc


func! s:nextnonblank(lnum) abort
    let res = nextnonblank(a:lnum)
    if res == 0
        let res = line('$')+1
    endif
    return res
endfunc


func! s:detect_nearest_line() abort
    let lnum = line('.')
    let nline = s:nextnonblank(lnum)
    let pline = prevnonblank(lnum)
    if abs(nline - lnum) > abs(pline - lnum) || getline(nline) =~ '^\s*$'
        return pline
    else
        return nline
    endif
endfunc
