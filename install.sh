#!/bin/bash
# Copyright 2018 Haoming Wang
set -e

app_name='xming-dotfiles'

[ -z "$APP_PATH" ] && APP_PATH="$(pwd)"
[ -z "$ZSH_CUSTOM" ] && ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

options=(
    "vim"
    "update-vim"
    "oh-my-zsh"
    "zsh-plugins"
    "python"
    "tmux"
    "sublime-vscode"
)

one_option_mode=''  # if we stay in option chosen loop

source utils.sh

############################ SETUP FUNCTIONS

print_select_menu() {
    local prev="$PS3"
    PS3=""
    echo toto | select foo in "${options[@]}"; do break; done  # dummy select
    PS3=$prev
}

############################ MAIN FUNCTIONS

install_vim() {
    program_must_exist  "vim"
    program_must_exist  "git"

    do_backup           "$HOME/.vim"
    do_backup           "$HOME/.vimrc"
    do_backup           "$HOME/.gvimrc"

    create_vim_symlinks "$APP_PATH"

    setup_vim_plug

    post_install_vim

    setup_nvim_if_exists
}

update_vim() {
    program_must_exist  "vim"

    setup_vim_plug

    setup_nvim_if_exists
}

install_oh_my_zsh() {
    program_must_exist  "zsh"
    program_must_exist  "git"
    program_must_exist  "curl"

    [ ! -d "$HOME/.oh-my-zsh" ] && sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    success "oh my zsh installed"
}

install_zsh_plugins() {
    program_must_exist  "zsh"
    file_must_exist     "$HOME/.zshrc"
    file_must_exist     "$HOME/.oh-my-zsh"

    config_zshrc        "$APP_PATH"
    install_zsh_plugin  "zsh-syntax-highlighting"
    install_zsh_plugin  "zsh-autosuggestions"
}

config_python() {
    mkdir -p $HOME/.ptpython
    lnif $APP_PATH/python/ptpython/config.py     $HOME/.ptpython
    mkdir -p $HOME/.pre-commit
    lnif $APP_PATH/python/pre-commit/config.yaml $HOME/.pre-commit
    install_miniconda_if_not_exists
    success "Now configuring python."
}

config_tmux() {
    program_must_exist  "tmux"
    lnif $APP_PATH/tmux/tmux.conf $HOME/.tmux.conf
    success "Now configuring tmux."
}

config_sublime_vscode() {
    program_exists "subl" && {
        local sublime_home
        local sublime_keymap
        is_linux && {
            sublime_home="$HOME/.config/sublime-text-3/Packages/User"
            sublime_keymap="Default (Linux).sublime-keymap"
        }
        if [ ! -z $sublime_home ] && [ -d $sublime_home ]; then
            for file in $APP_PATH/sublime/*.sublime-settings; do
                lnif $file $sublime_home
            done
            lnif "$APP_PATH/sublime/$sublime_keymap" $sublime_home
            success "Now configuring sublime-text."
        fi
    }

    program_exists "code" && {
        local code_home
        is_linux && code_home="$HOME/.config/Code/User"
        is_macos && code_home="$HOME/Library/Application Support/Code/User"
        increase_watch_limit
        watch_limit_is_increased && install_vscode_extensions
        if [ ! -z "$code_home" ]; then
            lnif $APP_PATH/vscode/settings.json    $code_home
            lnif $APP_PATH/vscode/keybindings.json $code_home
            for file in $APP_PATH/vscode/snippets/*.json; do
                lnif $file $code_home/snippets
            done
            success "Now configuring vscode."
        fi
    }
}

bye() {
    msg "\nThanks for installing $app_name."
    msg "© `date +%Y` http://flyingmouse.github.io/"
    exit 0
}

confirm() {
    [ ! -z $one_option_mode ] && bye
    read -p "Do you want to continue? (y/N) "
    case $REPLY in
        [yY][eE][sS]|[yY]) print_select_menu ;;
        *) bye ;;
    esac
}

while getopts "f" flag; do
    case $flag in
        f) one_option_mode=true; success "Entering one option mode" ;;
        *) error "Unexpected option ${flag}" ;;
    esac
done

PS3='Please enter your choice: '
select opt in "${options[@]}"; do
    case $opt in
        "vim")            install_vim ;;
        "update-vim")     update_vim ;;
        "oh-my-zsh")      install_oh_my_zsh ;;
        "zsh-plugins")    install_zsh_plugins ;;
        "python")         config_python ;;
        "tmux")           config_tmux ;;
        "sublime-vscode") config_sublime_vscode ;;
        *)                err "Unexpected option: $opt" ;;
    esac
    confirm
done
