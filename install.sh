#!/bin/bash
# Copyright 2018 Haoming Wang
set -e

app_name='xming-dotfiles'

[ -z "$APP_PATH" ] && APP_PATH="$(pwd)"
[ -z "$ZSH_CUSTOM" ] && ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

options=("vim" "update-vim" "oh-my-zsh" "zsh-plugins" "python" "tmux" "sublime-text")

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
    update_repo

    setup_vim_plug

    setup_nvim_if_exists
}

install_oh_my_zsh() {
    program_must_exist "zsh"
    program_must_exist "git"
    program_must_exist "curl"

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
    lnif $APP_PATH/ptpython/config.py $HOME/.ptpython
    install_miniconda_if_not_exists
    success "Now configuring python."
}

config_tmux() {
    lnif $APP_PATH/tmux/tmux.conf $HOME/.tmux.conf
    success "Now configuring tmux."
}

config_sublime() {
    if is_linux; then
        local sublime_home="$HOME/.config/sublime-text-3/Packages/User"
        if [ -d $sublime_home ]; then
            lnif $APP_PATH/sublime/sublime-settings     $sublime_home/Preferences.sublime-settings
            lnif $APP_PATH/sublime/sublime-keymap-linux $sublime_home/'Default (Linux).sublime-keymap'
            success "Now configuring sublime-text."
        fi
    fi
}

confirm() {
    [ ! -z $one_option_mode ] && exit 0
    read -p "Do you want to continue? (y/N) "
    case $REPLY in
        [yY][eE][sS]|[yY]) print_select_menu ;;
        *) exit 0 ;;
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
        "vim")          install_vim ;;
        "update-vim")   update_vim ;;
        "oh-my-zsh")    install_oh_my_zsh ;;
        "zsh-plugins")  install_zsh_plugins ;;
        "python")       config_python ;;
        "tmux")         config_tmux ;;
        "sublime-text") config_sublime ;;
        *)              err "Unexpected option: $opt" ;;
    esac
    confirm
done

msg             "\nThanks for installing $app_name."
msg             "© `date +%Y` http://flyingmouse.github.io/"
