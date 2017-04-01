set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/Vundle.vim'
Plugin 'scrooloose/nerdtree'
call vundle#end()

filetype plugin indent on

" enable syntax
syntax enable

" tab -> space
set tabstop=4
set softtabstop=4
set expandtab

" UI config
set number
set showcmd
set cursorline
set showmatch " show the matching part of the pair [] {} and ()

" Disable Arrow keys in Escape (normal) mode
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>

" Disable Arrow keys in Insert mode
imap <left> <nop>
imap <right> <nop>
imap <up> <nop>
imap <down> <nop>

" fuzzy find
set path+=**
set wildmenu

" set clipboard to system
set clipboard=unnamed

set splitbelow
set splitright
set backspace=eol,start,indent

set listchars=tab:>-,trail:~,extends:>,precedes:<
set list

set laststatus=2
" set modifiable to buffer, (I want to create a new folder in nerdtree)
set modifiable
