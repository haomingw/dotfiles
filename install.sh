#!/usr/bin/env bash

set -e

app_name='xming-dotfiles'

APP_PATH="$(dirname "$PWD/$0")"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

options=(
  "vim"
  "oh-my-zsh"
  "faster-zsh"
  "programming"
  "tmux-docker"
  "sublime-vscode"
)

zsh_plugins=(
  "z"
  "git"
  "zsh-users/zsh-autosuggestions"
  "zdharma/fast-syntax-highlighting"
  "zdharma/history-search-multi-word"
)

for ff in "$APP_PATH"/common/*; do
  # shellcheck disable=SC1090
  source "$ff"
done
# shellcheck disable=SC1090
source "$APP_PATH/utils.sh"

############################ SETUP FUNCTIONS

print_select_menu() {
  local prev="$PS3"
  PS3=""
  # dummy select
  echo toto | select _ in "${options[@]}"; do break; done
  PS3="$prev"
}

############################ MAIN FUNCTIONS

setup_vim() {
  program_must_exist  "git"
  must_have_one_of    "wget" "curl"

  install_vim
  install_neovim
  create_vim_symlinks
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

install_omz_plugins() {
  file_must_exist     "$HOME/.zshrc"
  file_must_exist     "$HOME/.oh-my-zsh"

  config_oh_my_zsh
  common_config_zsh
  # shellcheck disable=SC2046
  zsh_plug            $(reverse "${zsh_plugins[@]}")
}

custom_oh_my_zsh() {
  install_oh_my_zsh
  install_omz_plugins
}

custom_zinit() {
  program_must_exist  "git"
  program_must_exist  "zsh"

  do_backup           "$HOME/.zshrc" "pre-zinit"
  config_zinit
  common_config_zsh
}

config_programming_langs() {
  program_must_exist  "git"
  must_have_one_of    "wget" "curl"

  for f in "$APP_PATH"/python/*; do
    if [ -f "$f" ]; then
      lnif "$f" "$HOME/.$(parse "$f")"
    fi
  done

  install_miniconda
  install_golang
  install_go_tools
  install_node
  install_cargo
  install_ruby
  install_java
  install_swift

  success "Now configuring programming."
}

config_tmux_docker() {
  if program_exists tmux; then
    safe_mkdir "$HOME/.tmux/plugins"
    if [ ! -d ~/.tmux/plugins/tpm ]; then
      git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi
    lnif "$APP_PATH/tmux/tmux.conf" "$HOME/.tmux.conf"

    success "Now configuring tmux."
  fi

  if program_exists mpv; then
    local mpv_conf="$HOME/.config/mpv"
    safe_mkdir "$mpv_conf"
    lnif "$APP_PATH/mpv/input.conf" "$mpv_conf"

    success "Now configuring mpv."
  fi

  install_docker
}

config_sublime_vscode() {
  is_macos && {
    local dest="/usr/local/bin"
    lnif /Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl "$dest"
    lnif /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code "$dest"
  }

  local sublime_home sublime_keymap
  local link=lnif
  is_linux && {
    sublime_home="$HOME/.config/sublime-text-3/Packages/User"
    sublime_keymap="Default (Linux).sublime-keymap"
  }
  is_macos && {
    sublime_home="$HOME/Library/Application Support/Sublime Text/Packages/User"
    sublime_keymap="Default (OSX).sublime-keymap"
  }
  is_wsl && {
    link=cpif
    sublime_home="$WINHOME/AppData/Roaming/Sublime Text/Packages/User"
    sublime_keymap="Default (Windows).sublime-keymap"
  }
  local ff
  # shellcheck disable=SC2236
  if [ ! -z "$sublime_home" ] && [ -d "$sublime_home" ]; then
    for ff in "$APP_PATH"/sublime/*.sublime-settings; do
      $link "$ff" "$sublime_home"
    done
    $link "$APP_PATH/sublime/$sublime_keymap" "$sublime_home"

    success "Now configuring sublime-text."
  fi

  if program_exists "code"; then
    local code_home
    is_linux && code_home="$HOME/.config/Code/User"
    is_macos && code_home="$HOME/Library/Application Support/Code/User"
    is_wsl && code_home="$WINHOME/AppData/Roaming/Code/User"
    is_linux && increase_watch_limit
    install_vscode_extensions
    # shellcheck disable=SC2236
    if [ ! -z "$code_home" ]; then
      $link "$APP_PATH/vscode/settings.json" "$code_home"
      $link "$APP_PATH/vscode/keybindings.json" "$code_home"
      if is_linux; then
        rm -rf "$code_home/snippets"
        $link "$APP_PATH/vscode/snippets" "$code_home"
      else
        for ff in "$APP_PATH"/vscode/snippets/*; do
          $link "$ff" "$code_home/snippets"
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
    "vim")            setup_vim ;;
    "oh-my-zsh")      custom_oh_my_zsh ;;
    "faster-zsh")     custom_zinit ;;
    "programming")    config_programming_langs ;;
    "tmux-docker")    config_tmux_docker ;;
    "sublime-vscode") config_sublime_vscode ;;
    *)                error "Unexpected option: $1"; return 1 ;;
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
