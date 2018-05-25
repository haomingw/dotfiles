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
        let g:xming_plug_groups=['general', 'programming', 'youcompleteme']
    endif

    call plug#begin('~/.vim/bundle')

    " General {
        if count(g:xming_plug_groups, 'general')
            Plug 'jiangmiao/auto-pairs'
            Plug 'terryma/vim-multiple-cursors'
            Plug 'flazz/vim-colorschemes'
            Plug 'vim-airline/vim-airline'
            Plug 'vim-airline/vim-airline-themes'
        endif
    " }

    " Programming {
        if count(g:xming_plug_groups, 'programming')
            Plug 'luochen1990/rainbow'
            Plug 'tpope/vim-fugitive'
            Plug 'scrooloose/syntastic'
            Plug 'scrooloose/nerdcommenter'
            Plug 'easymotion/vim-easymotion'
            Plug 'nathanaelkane/vim-indent-guides'
        endif
    " }

    " Auto-completion {
        if count(g:xming_plug_groups, 'youcompleteme')
            Plug 'Valloric/YouCompleteMe', {'do': 'python3 ./install.py --clang-completer', 'for': ['cpp', 'python']}
        endif
    " }

     call plug#end()

" }

" General {

    " filetype plugin indent on
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

    set background=dark
    if isdirectory(expand("~/.vim/bundle/vim-colorschemes"))
        " color jellybeans
        color gruvbox
    endif

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

    set wrap
    set autoindent

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

    " Wrapped lines goes down/up to next row, rather than next line in file.
    nmap j gj
    nmap k gk

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
    nmap <leader>bg :call ToggleBG()<CR>

    " Visual shifting (does not exit Visual mode)
    vmap < <gv
    vmap > >gv

    cmap %% <C-R>=fnameescape(expand('%:h')).'/'<cr>
    map <leader>ew :e %%
    map <leader>es :sp %%
    map <leader>ev :vsp %%
    map <leader>et :tabe %%
    map <leader>rp :%s/

    " Switch between tabs
    map <a-h> gT
    map <a-l> gt

    " Fast move cursors
    nmap <c-e> <End>
    nmap <c-a> <Home>
    imap <c-e> <End>
    imap <c-a> <Home>
    imap <a-h> <Left>
    imap <a-j> <Down>
    imap <a-k> <Up>
    imap <a-l> <Right>

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
    nmap <c-s> :w<CR>
    imap <c-s> <Esc>:w<CR>a
    imap <s-cr> <Esc>o
    imap <c-s-cr> <Esc>O

    " utils
    nmap ; :
    nmap Y y$               " to be consistent with C and D.
    nmap  '. `.             " move to last modification
    cmap <c-v> <c-r>+       " yank text in command mode

" }

" Plugins {

    " Rainbow {
        if isdirectory(expand("~/.vim/bundle/rainbow/"))
            let g:rainbow_active = 1 " 0 if you want to enable it later via :RainbowToggle
        endif
    " }

    " Airline {
        " let g:airline_left_sep='›'  " Slightly fancier than '>'
        " let g:airline_right_sep='‹' " Slightly fancier than '<'
    " }

    " NerdCommenter {
        nmap <c-_> <leader>c<Space>
        vmap <c-_> <leader>c<Space>

        " Add spaces after comment delimiters by default
        let g:NERDSpaceDelims = 1
        " Allow commenting and inverting empty lines (useful when commenting a region)
        let g:NERDCommentEmptyLines = 1
    " }

    " Fugitive {
        if isdirectory(expand("~/.vim/bundle/vim-fugitive/"))
            nmap <silent> <leader>gs :Gstatus<CR>
            nmap <silent> <leader>gd :Gdiff<CR>
            nmap <silent> <leader>gc :Gcommit<CR>
            nmap <silent> <leader>gb :Gblame<CR>
            nmap <silent> <leader>gl :Glog<CR>
            nmap <silent> <leader>gp :Git push<CR>
            nmap <silent> <leader>gr :Gread<CR>
            nmap <silent> <leader>gw :Gwrite<CR>
            nmap <silent> <leader>ge :Gedit<CR>
            " Mnemonic _i_nteractive
            nmap <silent> <leader>gi :Git add -p %<CR>
            nmap <silent> <leader>gg :SignifyToggle<CR>
        endif
    "}

    " indent_guides {
        if isdirectory(expand("~/.vim/bundle/vim-indent-guides/"))
            let g:indent_guides_start_level = 2
            let g:indent_guides_guide_size = 1
            let g:indent_guides_enable_on_vim_startup = 1
        endif
    " }

    " Easymotion {
        if isdirectory(expand("~/.vim/bundle/vim-easymotion/"))
            let g:EasyMotion_leader_key = ','
            let g:EasyMotion_startofline = 0 " keep cursor column when JK motion
            let g:EasyMotion_smartcase = 1

            map <Leader>l <Plug>(easymotion-lineforward)
            map <Leader>h <Plug>(easymotion-linebackward)
            map <Leader>. <Plug>(easymotion-repeat)
        endif
    " }

    " YouCompleteMe {
        if isdirectory(expand("~/.vim/bundle/YouCompleteMe/"))
            let g:ycm_confirm_extra_conf = 0
            let g:ycm_global_ycm_extra_conf = $HOME . "/.vim/static/ycm_extra_conf.py"
            let g:ycm_add_preview_to_completeopt = 0
            let g:ycm_show_diagnostics_ui = 0
            let g:ycm_server_log_level = 'info'
            let g:ycm_min_num_identifier_candidate_chars = 2
            let g:ycm_collect_identifiers_from_comments_and_strings = 1
            let g:ycm_complete_in_strings=1
            set completeopt=menu,menuone
        endif
    " }

" }

" GUI Settings {

    " GVIM- (here instead of .gvimrc)
    if has('gui_running')
        set guioptions=             " remove all gui options
        set lines=40                " 40 lines of text instead of 24
        if LINUX()
            set guifont=Courier\ 10\ Pitch\ Regular\ 12,Andale\ Mono\ Regular\ 12,Menlo\ Regular\ 11,Consolas\ Regular\ 12,Courier\ New\ Regular\ 14
        elseif OSX()
            set guifont=Andale\ Mono:h12,Menlo:h11,Consolas:h12,Courier\ New:h14
        elseif WINDOWS()
            set guifont=Andale_Mono:h10,Menlo:h10,Consolas:h10,Courier_New:h10
        endif
    else
        if &term == 'xterm' || &term == 'screen'
            set t_Co=256            " Enable 256 colors to stop the CSApprox warning and make xterm vim shine
        endif
    endif

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
