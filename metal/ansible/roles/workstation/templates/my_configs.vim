" Show line numbers
set number

" Enable modern Vim features
set nocompatible

" Configure Nerdtree
map \ :NERDTreeToggle<cr>
let g:NERDTreeWinPos = "left"
let g:NERDTreeQuitOnOpen = 1

" Enable auto-indent and highlighting
filetype plugin indent on
syntax on

" Fix delay in exiting insert mode
set noesckeys
