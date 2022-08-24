" Used to indicate that .config/nvim/init.vim should not be loaded
let g:no_home_init=1

" Leader mapping
let mapleader = " "                               " set leader to <SPACE>
nnoremap <SPACE> <Nop>
"tnoremap <C-[> <C-\><C-N>                         " a more convenient escape from terminal

" Default options
set sw=4
set ts=4
set expandtab
set completeopt=menu,noinsert,menuone
set splitbelow
set splitright

set wildmode=longest:full,full       " Bash-like longest match
set wildmenu
set laststatus=2
set backspace=2                      " Deleting indentations et.c.

set scrolloff=3                                   " keep margin around scrolling
set sidescrolloff=3                               " same but for columns

set nojoinspaces                                  " join lines with single space instead of two.

set formatoptions+=j                              " remove comment leader when joining comment lines
set formatoptions+=n                              " smart auto-indenting inside numbered lists

set background=light

set cursorline                                    " Horizontal cursor line indicator

set number
au TextYankPost * silent! lua vim.highlight.on_yank()


" File explorer
nnoremap <silent><C-n> :NvimTreeToggle<CR>
" Find current file with NERDTree
nnoremap <silent><leader>ntf :NvimTreeFindFile<cr>

" vim-powered terminal in split window
map <Leader>t :term ++close<cr>
tmap <Leader>t <c-w>:term ++close<cr>

" Visualization options
set termguicolors                                 " Bypass fixed terminal colors to allow 24bit

" FZF
" Add utilities from nix to path
" Themes are set based on colorscheme below using autocmds
let $PATH .= ':@bat@/bin:@ripgrep@/bin:@black@/bin'

" Follow symbolic links and prune dot directories
let $FZF_DEFAULT_COMMAND='find .  -type d -path \*/\.* -prune -o -not -name .\*  -follow -type f -print'
" Fzf window
let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.8, 'height': 0.8,'yoffset':0.5,'xoffset': 0.5, 'highlight': 'Todo', 'border': 'sharp' } }
nnoremap <C-p> :Buffers<CR>
nnoremap <C-o> :Files<CR>
nnoremap <C-k> :GitFiles<CR>
" FSWITCH
let g:fsnonewfiles = 'true'
nmap T :FSHere<cr>


" Basic file type
autocmd FileType nix setlocal sw=2 ts=2 sts=2
autocmd FileType cpp,c setlocal tw=100 cc=+0
autocmd FileType java setlocal ts=4 sts=4 sw=4 noexpandtab
autocmd FileType javascript setlocal ts=4 sts=4 sw=4 noexpandtab
autocmd FileType make setlocal ts=8 sts=8 sw=8 noexpandtab
autocmd FileType php setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType python setlocal ts=4 sts=4 sw=4 expandtab  tw=100 cc=+0
autocmd FileType sh setlocal ts=4 sts=4 sw=4 expandtab cc=100
autocmd FileType tcl setlocal ts=4 sts=4 sw=4 expandtab
autocmd FileType vim setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType lua setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType yaml setlocal ts=4 sts=4 sw=4 expandtab
autocmd FileType rst,markdown setlocal tw=100 sw=4 expandtab
      \ formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
"
" C++
augroup eso_cpp
  au!
  au BufEnter *.h,*.hpp let b:fswitchdst = 'C,cpp,cc,cxx'
  au BufEnter *.h,*.ipp,*.hpp let b:fswitchlocs = '../src,reg:|include/.*||,reg:|src/include/.*|test|'

  au BufEnter *.cpp,*.cxx,*.cc let b:fswitchdst = 'hpp,h,hxx'
  au BufEnter *.cpp,*.cxx,*.cc let b:fswitchlocs = '.,../include,include/**,../test/**'
augroup END

augroup filetypedetect
    autocmd BufNew,BufNewFile,BufRead wscript setlocal filetype=python
    autocmd BufNew,BufNewFile,BufRead *.resource setlocal filetype=robot
augroup END

" Disable numbering in terminals
autocmd TermOpen * setlocal nonumber norelativenumber

" Highlight line in the gutter but not the full line
autocmd ColorScheme *
      \ highlight CursorLineNr cterm=reverse gui=reverse |
      \ highlight clear CursorLine

" Fix up difficult to see hop motion indicators
autocmd ColorScheme *
      \ highlight! link HopNextKey DiffDelete |
      \ highlight! link HopNextKey1 DiffText |
      \ highlight! link HopNextKey2 DiffChange

" Fix up bat themes based on current colorscheme
autocmd Colorscheme solarized
      \ let $BAT_THEME = (&background == 'dark' ? 'Solarized (dark)' : 'Solarized (light)')

autocmd Colorscheme nord
      \ let $BAT_THEME = 'Nord'

autocmd Colorscheme gruvbox
      \ let $BAT_THEME = (&background == 'dark' ? 'gruvbox-dark' : 'gruvbox-light')

onoremap <silent>ii :<C-u>call text#obj_indent(v:true)<CR>
onoremap <silent>ai :<C-u>call text#obj_indent(v:false)<CR>
xnoremap <silent>ii :<C-u>call text#obj_indent(v:true)<CR>
xnoremap <silent>ai :<C-u>call text#obj_indent(v:false)<CR>

" Simple command for formatting with black
command! Black
            \   execute 'silent !@black@/bin/black ' . shellescape(expand('%'))
            \ | execute 'redraw!'
