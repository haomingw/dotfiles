#!/bin/bash

############################  BASIC SETUP TOOLS

program_must_exist() {
  program_exists "$1" || {
    error "You must have '$1' installed to continue."
    exit 1
  }
}

file_must_exist() {
  local file_path="$1"

  if [ ! -f "$file_path" ] && [ ! -d "$file_path" ]; then
    error "You must have '$1' to continue."
    exit 1
  fi
}

git_clone_to() {
  local git_url="$1"
  local target_path="$2"

  local repo_name
  repo_name=$(basename "$git_url" .git)

  if [ -d "$target_path" ] && [ ! -d "$target_path/$repo_name" ]; then
    cd "$target_path" && git clone "$git_url"
  fi
}

parse_filename() {
  echo "$1" | rev | cut -d'/' -f1 | rev
}

update_vim_plugins() {
  if [ -z "$CI" ]; then
    vim +PlugClean! +qall && vim +PlugUpdate +qall
  else
    vim +PlugClean! +qall >/dev/null 2>&1
    vim +PlugUpdate +qall >/dev/null 2>&1
  fi
}

############################ SETUP FUNCTIONS

do_backup() {
  if [ -e "$1" ]; then
    msg "Attempting to back up your original configuration."
    today=$(date +%Y%m%d_%s)
    [ -e "$1" ] && [ ! -L "$1" ] && mv -v "$1" "$1.$today";
    success "Your original configuration has been backed up."
   fi
}

create_vim_symlinks() {
  local app="$1"

  mkdir -p "$HOME/.vim/undo"
  for file in "$app"/vim/vim/*; do
    lnif "$file" "$HOME/.vim/$(parse "$file")"
  done
  lnif "$app/vim/vimrc"                   "$HOME/.vimrc"
  lnif "$app/vim/ideavimrc"               "$HOME/.ideavimrc"

  lnif "$app/vim/vim/static/clang-format" "$HOME/.clang-format"
  lnif "$app/vim/vim/static/style.yapf"   "$HOME/.style.yapf"

  success "Setting up vim symlinks."
}

setup_neovim() {
  mkdir -p "$HOME/.config"
  if is_macos; then
    if [ -f /usr/local/bin/pip3 ]; then
      /usr/local/bin/pip3 install -U neovim
    else
      warning "Run 'brew install python'"
    fi
  fi
  lnif "$HOME/.vim"     "$HOME/.config/nvim"
  lnif "$HOME/.vimrc"   "$HOME/.config/nvim/init.vim"

  success "Setting up neovim."
}

setup_vim_plug() {
  local system_shell="$SHELL"
  export SHELL='/bin/sh'

  update_vim_plugins

  export SHELL="$system_shell"

  success "Now updating/installing plugins using vim-plug"
}

use_zsh_plugin() {
  local target="$HOME/.zshrc"
  # shellcheck disable=SC1003
  sed -i -e 's/^plugins=(/&\'$'\n'"  $1/" "$target"
}

clear_zsh_plugins() {
  sed -i -e '/^plugins/,/^)/{/^plugins/!{/^)/!d;};}' "$HOME/.zshrc"
}

zsh_plug() {
  clear_zsh_plugins

  local custom_plugins="$ZSH_CUSTOM/plugins"

  for plugin in "$@"; do
    if [[ "$plugin" == */* ]]; then
      local name
      name=$(parse "$plugin")
      use_zsh_plugin "$name"
      if [ ! -d "$custom_plugins/$name" ]; then
        git_clone_to https://github.com/"$plugin".git "$custom_plugins"
      else
        pushd "$custom_plugins/$name" && git pull && popd || exit
      fi
    else
      use_zsh_plugin "$plugin"
    fi
    msg "Now installing zsh plugin $plugin."
  done
}

append_if_not_exists() {
  local file="$1"
  local content="$2"
  if [ ! -f "$file" ] || ! grep -q "$content" "$file"; then
    echo "$content" >> "$file"
  fi
}

config_zshrc() {
  local app_path="$1"
  local zshrc="$HOME/.zshrc"

  # shellcheck disable=SC1003
  sed -i -e 's/plugins=(git)/plugins=(\'$'\n  git\\'$'\n)/' "$zshrc"
  lnif "$app_path/common" "$HOME/.common"
  for file in "$app_path"/zsh/*; do
    lnif "$file" "$HOME/.$(parse "$file")"
  done

  local custom_themes="$ZSH_CUSTOM/themes"
  for file in "$app_path"/zsh/zsh/themes/*; do
    lnif "$file" "$custom_themes/$(basename "$file" .zsh).zsh-theme"
  done

  # shellcheck disable=SC2016
  local cmd='[[ -s $HOME/.zshrc.local ]] && source $HOME/.zshrc.local'
  append_if_not_exists "$zshrc" "$cmd"

  # set ibus for archlinux
  program_exists pacman && {
    append_if_not_exists "$HOME/.profile" "ibus-daemon -drx"
  }

  success "Now configuring zsh."
}

config_i3wm() {
  local app_path="$1"
  local dest="$HOME/.config/i3"

  [ -d "dest" ] || mkdir -p "$dest"

  for file in "$app_path"/i3/*; do
    lnif "$file" "$dest"
  done

  success "Now configuring i3wm."
}

cleanup_miniconda_files() {
  local installation_file="$1"

  rm "$installation_file"
  find "$HOME/miniconda3" \( -type f -o -type l \) \
    -not -path "$HOME/miniconda3/pkgs*" \
    -regex ".*bin/wish[0-9\.]*$" -ls -delete
  success "Cleaning up minconda files"
}

install_miniconda() {
  local conda="$HOME/miniconda3"
  local init_pip_packages="$HOME/.pip_packages"
  local python_packages=(
    "jedi"
    "flake8"
    "mypy"
    "yapf"
  )

  if [ ! -d "$conda" ]; then
    local url
    local conda_repo="https://repo.anaconda.com/miniconda"
    is_linux && url="$conda_repo/Miniconda3-latest-Linux-x86_64.sh"
    is_macos && url="$conda_repo/Miniconda3-latest-MacOSX-x86_64.sh"
    # shellcheck disable=SC2236
    if [ ! -z "$url" ]; then
      local miniconda
      miniconda=$(parse_filename $url)
      local target="/tmp"
      [ -f "$target/$miniconda" ] || wget $url -P $target
      bash "$target/$miniconda" \
      && success "Miniconda successfully installed" \
      && cleanup_miniconda_files "$target/$miniconda"
      success "Writing pip packages to $init_pip_packages"
      "$conda"/bin/pip freeze > "$init_pip_packages"
    fi
  fi
  for package in "${python_packages[@]}"; do
    "$conda"/bin/pip install -U "$package"
  done
}

install_cargo() {
  local cargo="$HOME/.cargo"

  if [[ ! -d "$cargo" ]]; then
    local target='/tmp/install-rust.sh'
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > "$target"
    sh "$target" -y --no-modify-path
    rm "$target"
  fi

  local packages=(
    "fd-find"
    "ripgrep"
  )
  for package in "${packages[@]}"; do
    "$cargo"/bin/cargo install "$package"
  done
}

watch_limit_is_increased() {
  program_exists sysctl && {
    local limit
    limit=$(sysctl fs.inotify.max_user_watches | cut -d' ' -f3)
    [ "$limit" -ge 524288 ]
  }
}

increase_watch_limit() {
  # if the limit has been increased, do nothing
  watch_limit_is_increased && return 0

  local watch_limit="fs.inotify.max_user_watches=524288"
  local cfg
  program_exists apt && cfg="/etc/sysctl.conf"
  program_exists pacman && cfg="/etc/sysctl.d/50-max_user_watches.conf"
  local message=(
    "Do you want to increase (requires sudo password)"
    "inotify limit? (y/N) "
  )
  # shellcheck disable=SC2236
  if [ ! -z "$cfg" ] && [ -r "$cfg" ]; then
    # shellcheck disable=SC2162
    read -p "${message[*]}"
    case $REPLY in
      [yY][eE][sS]|[yY]) ;;
      *) return 0 ;;
    esac
    grep -q "$watch_limit" "$cfg" || {
      echo "$watch_limit" | sudo tee -a "$cfg" >/dev/null
    }
    program_exists apt && sudo sysctl -p >/dev/null
    program_exists pacman && sudo sysctl --system >/dev/null
    success "Increasing inotify watcher limit"
  fi
}

install_vscode_extensions() {
  local extensions=(
    "ms-vscode.go"
    "eamodio.gitlens"
    "ms-python.python"
    "mitaki28.vscode-clang"
  )
  for extension in "${extensions[@]}"; do
    code --install-extension "$extension"
  done
  success "Vscode extensions are installed"
}
