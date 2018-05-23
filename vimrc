" Modeline and Notes {
" vim: set sw=4 ts=4 sts=4 et tw=78 foldmarker={,} foldlevel=0 foldmethod=marker nospell:
"
" Author: Haoming Wang <haoming.exe@gmail.com>
" }

" Environment {

    " Identify platform {
        silent function! OSX()
            return has('macunix')
        endfunction
        silent function! LINUX()
            return has('unix') && !has('macunix') && !has('win32unix')
        endfunction
        silent function! WINDOWS()
            return  (has('win32') || has('win64'))
        endfunction
    " }

    " Basics {
        set nocompatible        " Must be first line
    " }

    " Windows Compatible {
        " On Windows, also use '.vim' instead of 'vimfiles'; this makes synchronization
        " across (heterogeneous) systems easier.
        if WINDOWS()
          set runtimepath=$HOME/.vim,$VIM/vimfiles,$VIMRUNTIME
        endif
    " }

" }

" Bundles {

    " list only the plugin groups you will use
    if !exists('g:xming_plug_groups')
        let g:xming_plug_groups=['general', 'programming']
    endif

    call plug#begin('~/.vim/bundle')

    " General {
        if count(g:xming_plug_groups, 'general')
            Plug 'terryma/vim-multiple-cursors'
            Plug 'flazz/vim-colorschemes'
            Plug 'vim-airline/vim-airline'
            Plug 'vim-airline/vim-airline-themes'
        endif
    " }

    " Programming {
        if count(g:xming_plug_groups, 'programming')
            Plug 'scrooloose/syntastic'
        endif
    " }

     call plug#end()

" }

" General {

    set guioptions=
    filetype plugin indent off
    syntax on                   " Syntax highlighting
    set mouse=a                 " Automatically enable mouse usage
    set mousehide               " Hide the mouse cursor while typing
    scriptencoding utf-8

    if has('clipboard')
        if has('unnamedplus')  " When possible use + register for copy-paste
            set clipboard=unnamed,unnamedplus
        else         " On mac and Windows, use * register for copy-paste
            set clipboard=unnamed
        endif
    endif

    if !exists('g:xming_no_restore_cursor')
        function! ResCur()
            if line("'\"") <= line("$")
                silent! normal! g`"
                return 1
            endif
        endfunction

        augroup resCur
            autocmd!
            autocmd BufWinEnter * call ResCur()
        augroup END
    endif

    set shortmess+=filmnrxoOtT          " Abbrev. of messages (avoids 'hit enter')
    set viewoptions=folds,options,cursor,unix,slash " Better Unix / Windows compatibility
    set virtualedit=onemore             " Allow for cursor beyond last character
    set history=200
    set hidden                          " Allow buffer switching without saving
    set iskeyword-=.                    " '.' is an end of word designator
    set iskeyword-=#                    " '#' is an end of word designator
    set iskeyword-=-                    " '-' is an end of word designator

    set nobackup noswapfile nowritebackup
    if has('persistent_undo')
        set undofile                " So is persistent undo ...
        set undodir=$HOME/.vim/undo
        set undolevels=1000         " Maximum number of changes that can be undone
        set undoreload=10000        " Maximum number lines to save for undo on a buffer reload
    endif

" }

" Vim UI {

    "set background=dark
    color molokai

    set number                      " Line numbers on
    set cursorline                  " Highlight current line
    set showmode                    " Display the current mode
    set showcmd                     " Show partial commands in status line
    set backspace=indent,eol,start  " Backspace for dummies
    set linespace=0                 " No extra spaces between rows
    set showmatch                   " Show matching brackets/parenthesis
    set incsearch                   " Find as you type search
    set hlsearch                    " Highlight search terms
    set winminheight=0              " Windows can be 0 line high
    set ignorecase                  " Case insensitive search
    set smartcase                   " Case sensitive when uc present
    set wildmenu                    " Show list instead of just completing
    set wildmode=list:longest,full  " Command <Tab> completion, list matches, then longest common part, then all.
    set whichwrap=b,s,h,l,<,>,[,]   " Backspace and cursor keys wrap too
    set scrolljump=5                " Lines to scroll when cursor leaves screen
    set scrolloff=3                 " Minimum lines to keep above and below cursor
    set foldenable                  " Auto fold code
    set list
    set listchars=tab:›\ ,trail:•,extends:#,nbsp:. " Highlight problematic whitespace

" }

" Formatting {

    set nowrap
    set autoindent smartindent

    set shiftwidth=4                " Use indents of 4 spaces
    set expandtab                   " Tabs are spaces, not tabs
    set tabstop=4                   " An indentation every four columns
    set softtabstop=4               " Let backspace delete indent

    set splitright splitbelow
    set pastetoggle=<F12>           " pastetoggle (sane indentation on pastes)
    set nojoinspaces                " Prevents inserting two spaces after punctuation on a join (J)
    autocmd FileType c,cpp,java,go,php,javascript,puppet,python,rust,twig,xml,yml,perl,sql autocmd BufWritePre <buffer> call StripTrailingWhitespace()

" }

" Key (re)Mappings {

    " The default leader is '\', but many people prefer ',' as it's in a standard
    " location.
    let mapleader = ','
    let maplocalleader = '_'

    " Allow to trigger background
    function! ToggleBG()
        let s:tbg = &background
        " Inversion
        if s:tbg == "dark"
            set background=light
        else
            set background=dark
        endif
    endfunction
    noremap <leader>bg :call ToggleBG()<CR>

    " Visual shifting (does not exit Visual mode)
    vmap < <gv
    vmap > >gv

    cnoremap %% <C-R>=fnameescape(expand('%:h')).'/'<cr>
    map <leader>ew :e %%
    map <leader>es :sp %%
    map <leader>ev :vsp %%
    map <leader>et :tabe %%
    map <leader>rp :%s/

    " Yank from the cursor to the end of the line, to be consistent with C and D.
    nmap Y y$

    " Switch between tabs
    map <a-h> gT
    map <a-l> gt

    " Fast move cursors
    nmap <c-e> $
    imap <c-h> <Left>
    imap <c-j> <Down>
    imap <c-k> <Up>
    imap <c-l> <Right>
    imap <c-e> <End>
    imap <a-f> <Esc>wi
    imap <a-b> <Esc>bi

    " Window:
    nmap <c-w><Right> 4<c-w>>
    nmap <c-w><Left> 4<c-w><
    nmap <c-w><Down> 4<c-w>+
    nmap <c-w><Up> 4<c-w>-
    nmap <c-h> <c-w>h
    nmap <c-l> <c-w>l
    nmap <c-k> <c-w>k
    nmap <c-j> <c-w>j

    " Fast editting
    nnoremap ; :
    nmap <c-s> :w<CR>
    imap <c-s> <Esc>:w<CR>a
    imap <s-cr> <Esc>o
    imap <c-s-cr> <Esc>O
" }

" Plugins {


" }

" Functions {

    " Strip whitespace {
    function! StripTrailingWhitespace()
        " Preparation: save last search, and cursor position.
        let _s=@/
        let l = line(".")
        let c = col(".")
        " do the business:
        %s/\s\+$//e
        " clean up: restore previous search history, and cursor position
        let @/=_s
        call cursor(l, c)
    endfunction
    " }

" }
