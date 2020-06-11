#!/bin/bash
# Copyright 2018 Haoming Wang

set -e

app_name='xming-dotfiles'

APP_PATH="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

options=(
  "vim"
  "oh-my-zsh"
  "zsh-plugins"
  "python-rust"
  "tmux-lf-mpv"
  "sublime-vscode"
)

zsh_plugins=(
  "z"
  "git"
  "zsh-users/zsh-autosuggestions"
  "zdharma/fast-syntax-highlighting"
  "zdharma/history-search-multi-word"
)

for file in "$APP_PATH"/common/*; do
  # shellcheck disable=SC1090,SC1091
  source "$file"
done
# shellcheck disable=SC1090,SC1091
source "$APP_PATH/utils.sh"

############################ SETUP FUNCTIONS

print_select_menu() {
  local prev="$PS3"
  PS3=""
  echo toto | select _ in "${options[@]}"; do break; done  # dummy select
  PS3=$prev
}

############################ MAIN FUNCTIONS

install_or_update_vim() {
  program_must_exist  "vim"
  program_must_exist  "git"

  create_vim_symlinks "$APP_PATH"

  setup_neovim

  setup_vim_plug
}

install_oh_my_zsh() {
  program_must_exist  "zsh"
  program_must_exist  "git"
  program_must_exist  "curl"

  [ ! -d "$HOME/.oh-my-zsh" ] && {
    export RUNZSH=no
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  }
  success "oh my zsh installed"
}

install_zsh_plugins() {
  program_must_exist  "zsh"
  file_must_exist     "$HOME/.zshrc"
  file_must_exist     "$HOME/.oh-my-zsh"

  config_zshrc        "$APP_PATH"
  config_i3wm         "$APP_PATH"  # linux only
  # shellcheck disable=SC2046
  zsh_plug            $(reverse "${zsh_plugins[@]}")
}

config_python_rust() {
  rm -rf ~/.ptpython ~/.linter
  lnif "$APP_PATH/python/ptpython" ~/.ptpython
  lnif "$APP_PATH/python/linter"   ~/.linter

  install_miniconda
  install_cargo

  success "Now configuring python-rust."
}

config_tmux_lf_mpv() {
  program_exists tmux && {
    mkdir -p ~/.tmux/plugins
    if [ ! -d ~/.tmux/plugins/tpm ]; then
      git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi
    lnif "$APP_PATH/tmux/tmux.conf" "$HOME/.tmux.conf"

    success "Now configuring tmux"
  }

  program_exists lf || {
    if program_exists go; then
      msg "Installing lf file manager"
      go get -u github.com/gokcehan/lf
    else
      warning "You must have Go installed to configure lf."
    fi
  }
  program_exists lf || program_exists go && {
    local lfrc="$HOME/.config/lf"
    [ -d "$lfrc" ] || mkdir -p "$lfrc"
    lnif "$APP_PATH/lf/lfrc" "$lfrc"

    success "Now configuring lf"
  }

  program_exists mpv && {
    local mpv_conf="$HOME/.config/mpv"
    [ -d "$mpv_conf" ] || mkdir -p "$mpv_conf"
    lnif "$APP_PATH/mpv/input.conf" "$mpv_conf"

    success "Now configuring mpv"
  }
}

config_sublime_vscode() {
  is_macos && {
    local dest='/usr/local/bin'
    lnif /Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl $dest
    lnif /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code $dest
  }

  program_exists "subl" && {
    local sublime_home
    local sublime_keymap
    is_linux && {
      sublime_home="$HOME/.config/sublime-text-3/Packages/User"
      sublime_keymap="Default (Linux).sublime-keymap"
    }
    is_macos && {
      sublime_home="$HOME/Library/Application Support/Sublime Text 3/Packages/User"
      sublime_keymap="Default (OSX).sublime-keymap"
    }
    # shellcheck disable=SC2236
    if [ ! -z "$sublime_home" ] && [ -d "$sublime_home" ]; then
      for file in "$APP_PATH"/sublime/*.sublime-settings; do
        lnif "$file" "$sublime_home"
      done
      lnif "$APP_PATH/sublime/$sublime_keymap" "$sublime_home"
      success "Now configuring sublime-text."
    fi
  }

  # shellcheck disable=SC2015
  program_exists "code" && {
    local code_home
    is_linux && code_home="$HOME/.config/Code/User"
    is_macos && code_home="$HOME/Library/Application Support/Code/User"
    is_linux && increase_watch_limit
    install_vscode_extensions
    # shellcheck disable=SC2236
    if [ ! -z "$code_home" ]; then
      lnif "$APP_PATH/vscode/settings.json" "$code_home"
      lnif "$APP_PATH/vscode/keybindings.json" "$code_home"
      if is_linux; then
        rm -rf "$code_home/snippets"
        lnif "$APP_PATH/vscode/snippets" "$code_home"
      else
        for file in "$APP_PATH"/vscode/snippets/*; do
          lnif "$file" "$code_home/snippets"
        done
      fi
      success "Now configuring vscode."
    fi
  } || true
}

bye() {
  msg "Thanks for installing $app_name."
  msg "© $(date +%Y) http://flyingmouse.github.io/"
  exit 0
}

config() {
  case "$1" in
    "vim")            install_or_update_vim ;;
    "oh-my-zsh")      install_oh_my_zsh ;;
    "zsh-plugins")    install_zsh_plugins ;;
    "python-rust")    config_python_rust ;;
    "tmux-lf-mpv")    config_tmux_lf_mpv ;;
    "sublime-vscode") config_sublime_vscode ;;
    *)                error "Unexpected option: $1" ;;
  esac
}

repeat_config() {
  PS3='Please enter your choice: '
  select option in "${options[@]}"; do
    config "$option"
    confirm_finish
  done
}

confirm_finish() {
  # shellcheck disable=SC2015
  confirm "Do you want to continue?" && print_select_menu || bye
}

main() {
  # shellcheck disable=SC2015
  [ $# -eq 1 ] && config "$1" || repeat_config "$@"
}

main "$@"
