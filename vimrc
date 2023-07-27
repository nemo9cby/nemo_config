set nocompatible

filetype off
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

" fuzzy find
set path+=**
set wildmenu

" set clipboard to system
set clipboard=unnamedplus

set splitbelow
set splitright
set backspace=eol,start,indent

set listchars=tab:>-,trail:~,extends:>,precedes:<
set list

set laststatus=2
