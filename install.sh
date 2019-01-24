#!/bin/bash
#   Copyright 2018 Haoming Wang
set -e

app_name='xming-dotfiles'
[ -z "$APP_PATH" ] && APP_PATH="$(pwd)"
[ -z "$ZSH_CUSTOM" ] && ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
debug_mode='0'
options=("vim" "oh-my-zsh" "zsh-plugins")

. ./utils.sh

install_vim() {
    program_must_exist "vim"
    program_must_exist "git"

    do_backup       "$HOME/.vim"
    do_backup       "$HOME/.vimrc"
    do_backup       "$HOME/.gvimrc"

    create_symlinks "$APP_PATH" \
                    "$HOME"

    setup_vim_plug

    post_install_vim
}

install_zsh() {
    program_must_exist "zsh"
    program_must_exist "git"
    program_must_exist "curl"

    install_oh_my_zsh
}

config_zsh() {
    program_must_exist "zsh"

    install_zsh_plugins "$ZSH_CUSTOM/plugins"
    setup_zsh           "$APP_PATH/zsh" \
                        "$HOME"
}

confirm() {
    read -p "Do you want to continue? (y/N) " choice
    case $choice in
        [yY][eE][sS]|[yY] ) ;;
        * ) exit 0;;
    esac
}

PS3='Please enter your choice: '
select opt in "${options[@]}"; do
    case $opt in
        "vim") install_vim;;
        "oh-my-zsh") install_zsh;;
        "zsh-plugins") config_zsh;;
    esac
    confirm
done

msg             "\nThanks for installing $app_name."
msg             "© `date +%Y` http://flyingmouse.github.io/"