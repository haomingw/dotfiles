#!/usr/bin/env bash

############################  BASIC SETUP TOOLS

CHSH=${CHSH:-yes}
app_path="$(dirname "$PWD/$0")"

is_not_ci() {
  [ -z "$CI" ]
}

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

  if [ ! -d "$target_path/$repo_name" ]; then
    git clone "$git_url" "$target_path/$repo_name"
  fi
}

git_pull() {
  pushd "$1" >/dev/null && git pull && popd >/dev/null || return 1
}

update_vim_plugins() {
  if is_not_ci; then
    vim +PlugClean! +qall && vim +PlugUpdate +qall
  else
    vim +PlugClean! +qall >/dev/null 2>&1
    vim +PlugUpdate +qall >/dev/null 2>&1
  fi
}

add_apt_repo() {
  msg "Adding apt repo $1."
  sudo add-apt-repository -y "$1"
  sudo apt update
}

safe_install() {
  local prog=${2:-$1}
  if ! program_exists "$1"; then
    if is_ubuntu; then
      msg "Installing $prog."
      sudo apt install -y "$prog"
    fi
  fi
}

safe_add_repo() {
  local pattern="$1"
  local repo="$2"

  if is_ubuntu; then
    if apt_repo_exists "$pattern"; then
      msg "$pattern repo is up to date."
    else
      add_apt_repo "$repo"
    fi
  fi
}

append_if_not_exists() {
  local file="$1"
  local content="$2"
  if [ ! -f "$file" ] || ! grep -q "$content" "$file"; then
    echo "$content" >> "$file"
  fi
}

############################ SETUP FUNCTIONS

do_backup() {
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    msg "Attempting to back up your original configuration."
    local suffix
    suffix=${2:-$(date +%Y%m%d_%s)}
    mv -v "$1" "$1.$suffix"
    success "Your original configuration has been backed up."
  fi
}

install_vim() {
  safe_add_repo "jonathonf-ubuntu-vim" "ppa:jonathonf/vim"
  safe_install vim
}

install_neovim() {
  safe_add_repo neovim "ppa:neovim-ppa/stable"
  safe_install nvim neovim
}

create_vim_symlinks() {
  safe_mkdir "$HOME/.vim/undo"
  local ff
  for ff in "$app_path"/vim/vim/*; do
    lnif "$ff" "$HOME/.vim/$(parse "$ff")"
  done

  lnif "$app_path/vim/vimrc"                   "$HOME/.vimrc"
  lnif "$app_path/vim/ideavimrc"               "$HOME/.ideavimrc"

  lnif "$app_path/vim/vim/static/clang-format" "$HOME/.clang-format"
  lnif "$app_path/vim/vim/static/style.yapf"   "$HOME/.style.yapf"

  success "Setting up vim symlinks."
}

setup_neovim() {
  safe_mkdir "$HOME/.config"
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

  safe_mkdir ~/.config/coc
  update_vim_plugins

  if is_not_ci; then
    program_exists go && vim +GoUpdateBinaries +qall
  fi

  export SHELL="$system_shell"

  success "Now updating/installing plugins using vim-plug."
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
    msg "Now installing zsh plugin $plugin."
    if [[ "$plugin" == */* ]]; then
      local name
      name=$(parse "$plugin")
      use_zsh_plugin "$name"
      if [ ! -d "$custom_plugins/$name" ]; then
        git_clone_to https://github.com/"$plugin".git "$custom_plugins"
      else
        git_pull "$custom_plugins/$name"
      fi
    else
      use_zsh_plugin "$plugin"
    fi
  done
}

config_oh_my_zsh() {
  local zshrc="$HOME/.zshrc"
  local backup="$HOME/.zshrc.pre-zinit"

  if [ -L "$zshrc" ] && [ -f "$backup" ]; then
    if grep -q "oh-my-zsh" "$backup"; then
      msg "Attempting to recover from your zshrc backup."
      mv -v "$backup" "$zshrc"
    fi
  fi

  # shellcheck disable=SC1003
  sed -i -e 's/plugins=(git)/plugins=(\'$'\n  git\\'$'\n)/' "$zshrc"
  sed -i -e 's/# DISABLE_MAGIC/DISABLE_MAGIC/' "$zshrc"

  local custom_themes="$ZSH_CUSTOM/themes"
  local ff
  for ff in "$app_path"/zsh/zsh/themes/*; do
    lnif "$ff" "$custom_themes/$(basename "$ff" .zsh).zsh-theme"
  done

  # shellcheck disable=SC2016
  local cmd='[[ -s $HOME/.zshrc.local ]] && source $HOME/.zshrc.local'
  append_if_not_exists "$zshrc" "$cmd"

  success "Now configuring zsh."
}

backup_shell() {
  # We're going to change the default shell, so back up the current one
  if [ -n "$SHELL" ]; then
    echo "$SHELL" > ~/.shell.pre-zinit
  else
    grep "^$USER:" /etc/passwd | awk -F: '{print $7}' > ~/.shell.pre-zinit
  fi
}

setup_shell() {
  # Run as unattended if stdin is closed
  [ ! -t 0 ] && CHSH=no
  [ "$CHSH" = no ] && return

  # If this user's login shell is already "zsh", do not attempt to switch.
  [ "$(basename "$SHELL")" = "zsh" ] && return

  # If this platform doesn't provide a "chsh" command, bail out.
  if ! program_exists chsh; then
    echo "I can't change your shell automatically because this system does not have chsh."
    echo "${BLUE}Please manually change your default shell to zsh${RESET}"
    return
  fi

  echo "${BLUE}Time to change your default shell to zsh:${RESET}"

  # Prompt for user choice on changing the default login shell
  printf "%sDo you want to change your default shell to zsh? [Y/n]%s " "${YELLOW}" "${RESET}"
  read -r opt
  case $opt in
    y*|Y*|"") msg "Changing the shell..." ;;
    n*|N*) msg "Shell change skipped."; return ;;
    *) msg "Invalid choice. Shell change skipped."; return ;;
  esac

  local zsh
  zsh="$(command -v zsh)"
  backup_shell

  # Actually change the default shell to zsh
  if ! sudo chsh -s "$zsh" "$USER"; then
    error "chsh command unsuccessful. Change your default shell manually."
  else
    echo "${GREEN}Shell successfully changed to '$zsh'.${RESET}"
    msg "Remember to log out and back in for this to take effect!"
  fi
}

config_zinit() {
  local zinit="$HOME/.zinit"
  if [ ! -d "$zinit" ]; then
    git clone https://github.com/zdharma/zinit.git "$zinit"
  else
    git_pull "$zinit"
  fi

  lnif "$app_path/zsh/zinitrc.zsh" "$HOME/.zshrc"
  safe_touch ~/.zshenv.local

  setup_shell

  success "Now configuring zinit."
}

config_i3wm() {
  local dest="$HOME/.config/i3"

  safe_mkdir "$dest"

  local ff
  for ff in "$app_path"/i3/*; do
    lnif "$ff" "$dest"
  done

  success "Now configuring i3wm."
}

config_ssh() {
  [ -z "$AUTH_USERS" ] && return 0

  local key
  local auth_keys="$HOME/.ssh/authorized_keys"
  read -ra users <<< "$AUTH_USERS"

  safe_touch "$auth_keys"
  for user in "${users[@]}"; do
    key="$(curl https://github.com/"$user".keys 2>/dev/null)"
    [ -z "$key" ] || {
      msg "Adding $user's github keys to ssh authorized_keys."
      grep -q "$key" "$auth_keys" || echo "$key $user" >> "$auth_keys"
    }
  done

  success "Now configuring ssh."
}

config_git() {
  # this is personal
  if program_exists gpg && [ "$USER" == "haoming" ]; then
    msg "Setting personal git config."
    lnif "$app_path/git/config" ~/.gitconfig
  fi
}

common_config_zsh() {
  lnif "$app_path/bin" "$HOME/.bin"
  lnif "$app_path/common" "$HOME/.common"

  local ff
  for ff in "$app_path"/zsh/*; do
    if [[ "$ff" != *zinit* ]]; then
      lnif "$ff" "$HOME/.$(parse "$ff")"
    fi
  done

  # set ibus for archlinux
  program_exists pacman && {
    append_if_not_exists "$HOME/.profile" "ibus-daemon -drx"
  }

  is_linux && config_i3wm
  config_ssh
  config_git
}

cleanup_miniconda_files() {
  local installation_file="$1"

  rm "$installation_file"
  find "$HOME/miniconda3" \( -type f -o -type l \) \
    -not -path "$HOME/miniconda3/pkgs*" \
    -regex ".*bin/wish[0-9\.]*$" -ls -delete
  success "Cleaning up miniconda files."
}

install_miniconda() {
  local conda="$HOME/miniconda3"
  local init_pip_packages="$HOME/.pip_packages"
  local python_packages=(
    "jedi"
    "flake8"
    "mypy"
    "yapf"
    "virtualenv"
  )

  if [ ! -d "$conda" ]; then
    local url
    local conda_repo="https://repo.anaconda.com/miniconda"
    is_linux && url="$conda_repo/Miniconda3-latest-Linux-x86_64.sh"
    is_macos && url="$conda_repo/Miniconda3-latest-MacOSX-x86_64.sh"
    # shellcheck disable=SC2236
    if [ ! -z "$url" ]; then
      local miniconda
      miniconda=$(parse $url)
      local target="/tmp"
      [ -f "$target/$miniconda" ] || wget $url -P $target
      bash "$target/$miniconda" \
      && success "Miniconda successfully installed." \
      && "$conda"/bin/conda update -y conda \
      && cleanup_miniconda_files "$target/$miniconda"

      [ -f "$conda"/bin/pip ] || "$conda"/bin/conda install -y pip

      msg "Writing pip packages to $init_pip_packages."
      "$conda"/bin/pip freeze > "$init_pip_packages"
    fi
  fi

  for package in "${python_packages[@]}"; do
    "$conda"/bin/pip install -U "$package"
  done
}

install_golang() {
  is_linux || return 0

  local goroot="$HOME/.golang"
  local url
  url="$(wget -qO- https://golang.org/dl/ | grep -oP '\/dl\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n1)"
  local version
  version="$(echo "$url" | grep -oP 'go[0-9\.]+' | head -c -2)"
  local filename
  filename=$(parse "$url")

  if [ -f "$goroot/VERSION" ] && [ "$(cat "$goroot/VERSION")" = "$version" ]; then
    msg "Golang is up to date."
  else
    if [ -f "$goroot/VERSION" ]; then
      msg "Updating Golang $(cat "$goroot/VERSION") -> $version"
    else
      msg "Installing Golang $version"
    fi
    [ -f "/tmp/$filename" ] || wget "https://golang.org$url" -P "/tmp"
    tar xzf "/tmp/$filename" -C /tmp
    cp -Tr /tmp/go "$goroot"
    rm -rf "/tmp/$filename" /tmp/go
  fi
}

install_node() {
  is_linux || return 0

  local node_home="$HOME/.node"
  local url
  url="$(wget -qO- https://nodejs.org/en/download/ | grep -oP 'https:\/\/nodejs\.org\/dist\/v([0-9\.]+)/node-v([0-9\.]+)-linux-x64\.tar\.xz')"
  local version
  version="$(echo "$url" | grep -oP 'v[0-9\.]+' | head -n1)"
  local filename
  filename=$(parse "$url")

  if [ -f "$node_home/bin/node" ] && [ "$("$node_home/bin/node" -v)" = "$version" ]; then
    msg "Node.js is up to date."
  else
    if [ -f "$node_home/bin/node" ]; then
      msg "Updating Node.js $("$node_home/bin/node" -v) -> $version"
    else
      msg "Installing Node.js $version"
    fi
    [ -f "/tmp/$filename" ] || wget "$url" -P "/tmp"
    tar xJf "/tmp/$filename" -C /tmp
    local node
    node="$(basename "$filename" .tar.xz)"
    cp -Tr "/tmp/$node" "$node_home"
    rm -rf "/tmp/$filename" "/tmp/$node"
  fi
}

install_docker() {
  # don not run on CI machines and non-ubuntu os
  is_not_ci || return 0
  is_ubuntu || return 0

  if program_exists docker; then
    msg "Docker already installed."
  else
    # allow apt to use a repository over HTTPS
    sudo apt install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg-agent \
      software-properties-common

    if apt_repo_exists docker; then
      msg "Docker repo is up to date."
    else
      # Add Docker’s official GPG key
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      sudo add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"
    fi

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    msg "Adding $USER to group docker"
    msg "Remember to log out and back in for this to take effect!"
    sudo usermod -aG docker "$USER"
    success "Now installing Docker."
  fi

  local version
  local current
  version="$(wget -qO- https://github.com/docker/compose/releases | grep -oP '([0-9\.]+)/docker-compose-Linux' | head -n1 | grep -oP '[0-9\.]+')"
  program_exists docker-compose && current="$(docker-compose --version | grep -oP '[0-9\.]+' | head -n1)"

  if [ "$current" = "$version" ]; then
    msg "Docker Compose is up to date."
  else
    if program_exists docker-compose; then
      msg "Updating Docker Compose $current -> $version"
    else
      msg "Downloading Docker Compose."
    fi
    local target="/usr/local/bin/docker-compose"
    sudo curl -L "https://github.com/docker/compose/releases/download/$version/docker-compose-$(uname -s)-$(uname -m)" -o "$target"
    msg "Making it executable."
    sudo chmod +x "$target"
    success "Now installing Docker Compose."
  fi
}

install_go_tools() {
  local go_tools=(
    "github.com/gokcehan/lf"
    "github.com/jesseduffield/lazygit"
    "github.com/jesseduffield/lazydocker"
  )
  local goroot="$HOME/.golang"
  local prog
  local go_bin
  program_exists go && go_bin="go"
  [ -f "$goroot/bin/go" ] && go_bin="$goroot/bin/go"

  if [ -n "$go_bin" ]; then
    for url in "${go_tools[@]}"; do
      prog=$(parse "$url")
      program_exists "$prog" || {
        msg "Installing $prog"
        GO111MODULE=on "$go_bin" get -u "$url" >/dev/null 2>&1
      }
    done

    local lfrc="$HOME/.config/lf"
    safe_mkdir "$lfrc"
    safe_mkdir "$HOME/.lftrash"
    lnif "$app_path/lf/lfrc" "$lfrc"

    success "Now configuring lf."
  else
    warning "You must have Go installed to configure its tools."
  fi
}

install_cargo() {
  program_exists gcc || {
    warning "You must have gcc installed to configure Rust."
    return 0
  }
  local cargo="$HOME/.cargo"

  if [ ! -d "$cargo" ]; then
    local target='/tmp/install-rust.sh'
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > "$target"
    sh "$target" -y --no-modify-path
    rm "$target"
  else
    "$cargo/bin/rustup" update
    msg "Rust is up to date."
  fi

  local packages=(
    "fd-find"
    "ripgrep"
  )
  for package in "${packages[@]}"; do
    "$cargo"/bin/cargo install "$package"
  done
}

install_ruby() {
  local rbenv="$HOME/.rbenv"

  [ -d "$rbenv" ] || {
    msg "Installing rbenv and ruby-build."
    git clone https://github.com/rbenv/rbenv.git "$rbenv"
    git clone https://github.com/rbenv/ruby-build.git "$rbenv"/plugins/ruby-build
  }
  git_pull "$rbenv"
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
    success "Increasing inotify watcher limit."
  fi
}

install_vscode_extensions() {
  local extensions=(
    "golang.go"
    "eamodio.gitlens"
    "ms-python.python"
    "mitaki28.vscode-clang"
  )
  for extension in "${extensions[@]}"; do
    code --install-extension "$extension"
  done
  success "Vscode extensions are installed."
}
