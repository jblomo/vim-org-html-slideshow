"""""""""""" Settings
setlocal wrap
setlocal showbreak=»\ 
setlocal comments+=b:+,n:*
setlocal formatlistpat=^\\s*[0-9+*]\\+[\\]:.)}\\t\ ]\\s*
setlocal formatoptions-=c formatoptions+=rn

" new slide
inoremap <s-CR> <ESC>o<ESC>ddi<CR>*  :slide:<ESC>Bhi
nmap <LocalLeader>s  o<ESC>ddi<CR>*  :slide:<ESC>Bhi

" new bullets
inoremap <c-CR> <ESC>A<CR><ESC>:s/[+*]/ /eg<CR>A + 
nmap <LocalLeader>b  A<CR><ESC>:s/[+*]/ /eg<CR>A + 

" new notes
inoremap <s-c-CR> <ESC>o<ESC>0C**  :notes:<ESC>Bhi
nmap <LocalLeader>n    o<ESC>0C**  :notes:<ESC>Bhi

"""""""""""" Configuration
let g:org_export_babel_evaluate = 1

if !exists('g:org_command_for_emacsclient') && (has('unix') || has('macunix'))
    let g:org_command_for_emacsclient = 'emacsclient'
endif

if has('win32') || has('win64')
    let s:cmd_line_quote_fix = '^'
else
    let s:cmd_line_quote_fix = ''
endif

""""""""""""" Export

function! OrgExportDashboard()
    if s:OrgHasEmacsVar() == 0
       return
    endif
    let save_more = &more | set nomore
    let save_showcmd = &showcmd | set noshowcmd
    " show export dashboard
    "let mydict = { 't':'template', 'a':'ascii', 'n':'latin1', 'u':'utf8',
    let mydict = { 't':'template', 'a':'ascii', 'A':'ascii', 'o':'odt', 'O':'odt-and-open',
            \     'n':'latin1', 'N':'latin1', 'u':'utf8','U':'utf8',
            \     'h':'html', 'b':'html-and-open', 'l':'latex', 
            \     'f':'freemind', 'j':'taskjuggler', 'k':'taskjuggler-and-open',
            \     'p':'pdf', 'd':'pdf-and-open', 'D':'docbook', 'g':'tangle',  
            \     'F':'current-file', 'P':'current-project', 'E':'all' } 
    echohl MoreMsg
    echo " Press key for export operation:"
    echo " --------------------------------"
    echo " [t]   insert the export options template block"
    echo " "
    echo " [a/n/u]  export as ASCII/Latin1/utf8  [A/N/U] ...and open in buffer"
    echo " "
    echo " [h] export as HTML"
    echo " [b] export as HTML and open in browser"
    echo " "
    echo " [l] export as LaTeX"
    echo " [p] export as LaTeX and process to PDF"
    echo " [d] . . . and open PDF file"
    echo " "
    echo " [o] export as ODT        [O] as ODT and open"
    echo " [D] export as DocBook"
    echo " [V] export as DocBook, process to PDF, and open"
    echo " [x] export as XOXO       [j] export as TaskJuggler"
    echo " [m] export as Freemind   [k] export as TaskJuggler and open"

    echo " [g] tangle file"
    echo " "
    echo " [F] publish current file"
    echo " [P] publish current project"
    echo " [E] publish all projects"
    echo " "
    echohl None
    let key = nr2char(getchar())
    for item in keys(mydict)
        if (item ==# key) && (item !=# 't')
            "let g:org_emacs_autoconvert = 1
            "call s:GlobalUnconvertTags(changenr())
            let exportfile = expand('%:t') 
            silent exec 'write'

            let orgpath = g:org_command_for_emacsclient . ' -n --eval '
            let g:myfilename = substitute(expand("%:p"),'\','/','g')
            let g:myfilename = substitute(g:myfilename, '/ ','\ ','g')
            " set org-mode to either auto-evaluate all exec blocks or evaluate none w/o
            " confirming each with yes/no
            if g:org_export_babel_evaluate == 1
                let g:mypart1 = '(let ((org-export-babel-evaluate t)(org-confirm-babel-evaluate nil)'
            else
                let g:mypart1 = '(let ((org-export-babel-evaluate nil)'
            endif
            let g:mypart1 .= '(buf (find-file \' . s:cmd_line_quote_fix . '"' . g:myfilename . '\' . s:cmd_line_quote_fix . '"))) (progn  (' 

            if item =~? 'g' 
                let g:mypart3 = ' ) (set-buffer buf) (not-modified) (kill-this-buffer) ))'
            else  
                let g:mypart3 = ' nil ) (set-buffer buf) (not-modified) (kill-this-buffer) ))'
            endif
            
            if item =~# 'F\|P\|E'
                let command_part2 = ' org-publish-' . mydict[key]
            elseif item == 'g'
                let command_part2 = ' org-babel-tangle'
            else
                let command_part2 = ' org-export-as-' . mydict[key]
            endif

            let orgcmd =  orgpath . s:cmd_line_quote_fix . '"' . g:mypart1 . command_part2 . g:mypart3 . s:cmd_line_quote_fix . '"'
            let g:orgcmd = orgcmd
            " execute the call out to emacs
            redraw
            echo "Export in progress. . . "
            if exists('*xolox#shell#execute')
                "silent! let g:expmsg = xolox#shell#execute(orgcmd . ' | cat ', 1)
                silent! call xolox#shell#execute(orgcmd , 1)
            else
                "execute '!' . orgcmd
                silent! execute '!' . orgcmd
            endif
            redraw
            echo "Export in progress. . . Export complete."
            break
        endif
    endfor
    if key ==# 't' 
        let template = [
                    \ '#+TITLE:     ' . expand("%p")
                    \ ,'#+AUTHOR:   '
                    \ ,'#+EMAIL:    '
                    \ ,'#+DATE:     ' . strftime("%Y %b %d %H:%M")
                    \ ,'#+DESCRIPTION: '
                    \ ,'#+KEYWORDS: '
                    \ ,'#+LANGUAGE:  en'
                    \ ,'#+OPTIONS:   H:3 num:t toc:t \n:nil @:t ::t |:t ^:t -:t f:t *:t <:t'
                    \ ,'#+OPTIONS:   TeX:t LaTeX:t skip:nil d:nil todo:t pri:nil tags:not-in-toc'
                    \ ,'#+INFOJS_OPT: view:nil toc:nil ltoc:t mouse:underline buttons:0 path:http://orgmode.org/org-info.js'
                    \ ,'#+EXPORT_SELECT_TAGS: export'
                    \ ,'#+EXPORT_EXCLUDE_TAGS: noexport'
                    \ ,'#+LINK_UP:   '
                    \ ,'#+LINK_HOME: '
                    \ ,'#+XSLT: '
                    \ ]
        silent call append(line('.')-1,template)
    elseif key =~# 'A\|N\|U'
        exec 'split ' . expand('%:r') . '.txt'
        normal gg
    endif

    let &more = save_more
    let &showcmd = save_showcmd

endfunction
