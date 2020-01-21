set tabstop=4 softtabstop=0 expandtab shiftwidth=4 smarttab

set list
set listchars=tab:>-

call plug#begin('~/.local/share/nvim/plugged')
" " Plugins
"
" File tree display
Plug 'scrooloose/nerdtree'
" Lightline
Plug 'itchyny/lightline.vim'

" " Themes
"
" Malokai theme
Plug 'kiddos/malokai.vim'

" " Syntax
"
" Odin
Plug 'Tetralux/odin.vim'
call plug#end()

set laststatus=2
syntax on
" colorscheme malokai

map <C-o> :NERDTreeToggle<CR>
