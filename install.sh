#!/bin/bash
#   Copyright 2018 Haoming Wang
set -e

app_name='xming-dotfiles'
[ -z "$APP_PATH" ] && APP_PATH="$(pwd)"
[ -z "$ZSH_CUSTOM" ] && ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
debug_mode='0'
options=("vim" "oh-my-zsh" "zsh-plugins")

. ./utils.sh

############################ SETUP FUNCTIONS

setup_vim_plug() {
    local system_shell="$SHELL"
    export SHELL='/bin/sh'

    vim +PlugInstall +qall

    export SHELL="$system_shell"

    success "Now updating/installing plugins using vim-plug"
}

post_install_vim() {
    local ret='0'
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

config_zshrc()     {
    local file_path=$HOME/.zshrc
    sed -i '/plugins=(git)/c \plugins=(\n  git\n)' $file_path
    append_to_file "alias cdd=\"cd ~/Documents/code\""         $file_path
    append_to_file ""                                          $file_path
    append_to_file "# added by Miniconda3 installer"           $file_path
    append_to_file 'export PATH=$HOME/miniconda3/bin:$PATH'    $file_path
    append_to_file ""                                          $file_path
    append_to_file 'export CUDA_HOME=/usr/local/cuda'          $file_path
    append_to_file 'export LD_LIBRARY_PATH=${CUDA_HOME}/lib64' $file_path
    append_to_file 'PATH=$CUDA_HOME/bin:$PATH'                 $file_path
    success        "Now configuring zsh."
}

############################ MAIN FUNCTIONS

install_vim() {
    program_must_exist "vim"
    program_must_exist "git"

    do_backup          "$HOME/.vim"
    do_backup          "$HOME/.vimrc"
    do_backup          "$HOME/.gvimrc"

    create_symlinks    "$APP_PATH" \
                       "$HOME"

    setup_vim_plug

    post_install_vim
}

install_oh_my_zsh() {
    program_must_exist "zsh"
    program_must_exist "git"
    program_must_exist "curl"

    [ ! -d "$HOME/.oh-my-zsh" ] && sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    config_zshrc
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
        "oh-my-zsh")   install_oh_my_zsh;;
        "zsh-plugins") install_zsh_plugins;;
    esac
    confirm
done

msg             "\nThanks for installing $app_name."
msg             "© `date +%Y` http://flyingmouse.github.io/"
