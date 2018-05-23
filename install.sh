#!/bin/bash

#   Copyright 2018 Haoming Wang

app_name='xming-dotfiles'
[ -z "$APP_PATH" ] && APP_PATH="$(pwd)"
debug_mode='0'

. ./utils.sh

do_backup   	"$HOME/.vim" \
                "$HOME/.vimrc" \
                "$HOME/.gvimrc"

create_symlinks "$APP_PATH" \
                "$HOME"

setup_vim_plug

post_install

msg             "\nThanks for installing $app_name."
msg             "© `date +%Y` http://flyingmouse.github.io/"