#!/bin/bash
# Copyright 2018 Haoming Wang
set -e

app_name='xming-dotfiles'
[ -z "$APP_PATH" ] && APP_PATH="$(pwd)"
[ -z "$ZSH_CUSTOM" ] && ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
debug_mode='0'
options=("vim" "update-vim" "oh-my-zsh" "zsh-plugins" "python" "tmux")

. ./utils.sh

############################ SETUP FUNCTIONS

setup_vim_plug() {
    local system_shell="$SHELL"
    export SHELL='/bin/sh'

    vim +PlugUpdate +qall

    export SHELL="$system_shell"

    success "Now updating/installing plugins using vim-plug"
}

post_install_vim() {
    mkdir -p ~/.vim/undo
    success "Postpone installation finished."
}

install_zsh_plugin() {
    local plugin_name=$1
    local plugin_path="$ZSH_CUSTOM/plugins"

    git_clone_to https://github.com/zsh-users/$plugin_name.git $plugin_path
    sed -i "/^plugins=/a \  $plugin_name" $HOME/.zshrc
    success "Now installing zsh plugin $plugin_name."
}

config_zshrc() {
    local zshrc=$HOME/.zshrc
    sed -i '/plugins=(git)/c \plugins=(\n  git\n)' $zshrc
    cat $APP_PATH/zsh/zshrc >> $zshrc
    success     "Now configuring zsh."
}

setup_nvim_if_exists() {
    if program_exists "nvim" && [ ! -d $HOME/.config/.nvim ]; then
        mkdir -p $HOME/.config
        lnif "$HOME/.vim"         "$HOME/.config/nvim"
        lnif "$HOME/.vimrc"       "$HOME/.config/nvim/init.vim"
        success "Setting up neovim."
    fi
}

############################ MAIN FUNCTIONS

install_vim() {
    program_must_exist "vim"
    program_must_exist "git"

    do_backup          "$HOME/.vim"
    do_backup          "$HOME/.vimrc"
    do_backup          "$HOME/.gvimrc"

    create_symlinks    "$APP_PATH"

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
    file_must_exist    "$HOME/.zshrc"
    file_must_exist     "$HOME/.oh-my-zsh"

    config_zshrc
    install_zsh_plugin  "zsh-syntax-highlighting"
    install_zsh_plugin  "zsh-autosuggestions"
}

config_python() {
    mkdir -p $HOME/.ptpython
    lnif $APP_PATH/ptpython/config.py $HOME/.ptpython
    success "Now configuring python."
}

config_tmux() {
    lnif $APP_PATH/tmux/tmux.conf $HOME/.tmux.conf
    success "Now configuring tmux."
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
        "vim")         install_vim;;
        "update-vim")  update_vim;;
        "oh-my-zsh")   install_oh_my_zsh;;
        "zsh-plugins") install_zsh_plugins;;
        "python")      config_python;;
        "tmux")        config_tmux;;
    esac
    confirm
done

msg             "\nThanks for installing $app_name."
msg             "© `date +%Y` http://flyingmouse.github.io/"
