#!/usr/bin/env bash

set -e

app_name='xming-dotfiles'

APP_PATH="$(dirname "$PWD/$0")"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

options=(
  "vim"
  "oh-my-zsh"
  "faster-zsh"
  "python-rust"
  "tmux-go-mpv"
  "sublime-vscode"
)

zsh_plugins=(
  "z"
  "git"
  "zsh-users/zsh-autosuggestions"
  "zdharma/fast-syntax-highlighting"
  "zdharma/history-search-multi-word"
)

go_tools=(
  "github.com/gokcehan/lf"
  "github.com/jesseduffield/lazygit"
  "github.com/jesseduffield/lazydocker"
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
  # dummy select
  echo toto | select _ in "${options[@]}"; do break; done
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

  local omz="https://raw.githubusercontent.com/\
robbyrussell/oh-my-zsh/master/tools/install.sh"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no sh -c "$(curl -fsSL $omz)"
  fi

  success "oh my zsh installed."
}

install_zsh_plugins() {
  program_must_exist  "zsh"
  file_must_exist     "$HOME/.zshrc"
  file_must_exist     "$HOME/.oh-my-zsh"

  config_zshrc        "$APP_PATH"
  if is_linux; then
    config_i3wm       "$APP_PATH"
  fi
  config_ssh
  # shellcheck disable=SC2046
  zsh_plug            $(reverse "${zsh_plugins[@]}")
}

custom_oh_my_zsh() {
  install_oh_my_zsh
  install_zsh_plugins
}

custom_zinit() {
  program_must_exist  "git"
  program_must_exist  "zsh"

  do_backup           "$HOME/.zshrc" "pre-zinit"
  config_zinit        "$APP_PATH"
  config_ssh
}

config_python_rust() {
  program_must_exist  "git"

  rm -rf ~/.ptpython ~/.linter
  lnif "$APP_PATH/python/ptpython" ~/.ptpython
  lnif "$APP_PATH/python/linter"   ~/.linter

  install_miniconda
  install_cargo
  install_ruby

  success "Now configuring python-rust."
}

config_tmux_go_mpv() {
  if program_exists tmux; then
    safe_mkdir "$HOME/.tmux/plugins"
    if [ ! -d ~/.tmux/plugins/tpm ]; then
      git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi
    lnif "$APP_PATH/tmux/tmux.conf" "$HOME/.tmux.conf"

    success "Now configuring tmux."
  fi

  if program_exists go; then
    local bin
    for url in "${go_tools[@]}"; do
      bin=$(parse "$url")
      program_exists "$bin" || {
        msg "Installing $bin"
        go get -u "$url"
      }
    done

    local lfrc="$HOME/.config/lf"
    safe_mkdir "$lfrc"
    lnif "$APP_PATH/lf/lfrc" "$lfrc"

    success "Now configuring lf."
  else
    warning "You must have Go installed to configure its tools."
  fi

  if program_exists mpv; then
    local mpv_conf="$HOME/.config/mpv"
    safe_mkdir "$mpv_conf"
    lnif "$APP_PATH/mpv/input.conf" "$mpv_conf"

    success "Now configuring mpv."
  fi
}

config_sublime_vscode() {
  is_macos && {
    local dest='/usr/local/bin'
    lnif /Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl $dest
    lnif /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code $dest
  }

  if program_exists "subl"; then
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
  fi

  if program_exists "code"; then
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
  fi
}

bye() {
  msg "Thanks for installing $app_name."
  msg "© $(date +%Y) http://flyingmouse.github.io/"
  exit
}

setup() {
  case "$1" in
    "vim")            install_or_update_vim ;;
    "oh-my-zsh")      custom_oh_my_zsh ;;
    "faster-zsh")     custom_zinit ;;
    "python-rust")    config_python_rust ;;
    "tmux-go-mpv")    config_tmux_go_mpv ;;
    "sublime-vscode") config_sublime_vscode ;;
    *)                error "Unexpected option: $1" ;;
  esac
}

select_setup() {
  PS3='Please enter your choice: '
  select option in "${options[@]}"; do
    setup "$option"
    confirm_finish
  done
}

confirm_finish() {
  # shellcheck disable=SC2015
  confirm "Do you want to continue?" && print_select_menu || bye
}

main() {
  if [ $# -eq 1 ]; then
    setup "$1"
  else
    select_setup
  fi
}

main "$@"
