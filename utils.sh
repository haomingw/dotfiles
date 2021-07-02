#!/usr/bin/env bash

############################  BASIC SETUP TOOLS

CHSH=${CHSH:-yes}
app_path="$(dirname "$PWD/$0")"

is_not_ci() {
  [ -z "${CI:-}" ]
}

program_must_exist() {
  program_exists "$1" || {
    error "You must have '$1' installed to continue."
    exit 1
  }
}

must_have_one_of() {
  for prog in "$@"; do
    program_exists "$prog" && return 0
  done
  error "You must have one of [$*] installed to continue."
  exit 1
}

file_must_exist() {
  local file_path="$1"

  if [ ! -f "$file_path" ] && [ ! -d "$file_path" ]; then
    error "You must have '$1' to continue."
    exit 1
  fi
}

download_to() {
  local name
  name=${3:-$(parse "$1")}
  if program_exists wget; then
    wget "$1" -P "$2"
  else
    curl -fsSL "$1" > "$2/$name"
  fi
}

download_stdout() {
  if program_exists wget; then
    wget -qO- "$1"
  else
    curl -fsSL "$1"
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
  if ! program_exists "$1" && program_exists apt; then
    msg "Installing $prog."
    admin apt install -y "$prog"
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
  local target="$1"
  local content="$2"
  if [ ! -f "$target" ] || ! grep -q "$content" "$target"; then
    echo "$content" >> "$target"
  fi
}

insert_after_matching() {
  local pattern="$1"
  local text="$2"
  local target="$3"

  if ! grep -q "$text" "$target"; then
    if [ -w "$target" ]; then
      sed -i "/$pattern/a $text" "$target"
    else
      sudo sed -i "/$pattern/a $text" "$target"
    fi
  fi
}

check_update() {
  local current="$1"
  local version="$2"
  local prog="$3"

  if [ "$current" = "$version" ]; then
    msg "$prog is up to date."
  else
    if [ -n "$current" ]; then
      msg "Updating $prog $current -> $version"
    else
      msg "Installing $prog $version"
    fi
    return 1
  fi
}

gpgdec() {
  msg "Decrypting file to $2"
  gpg --decrypt "$1" > "$2"
  chmod 600 "$2"
}

safe_gpgdec() {
  [ -f "$2" ] || gpgdec "$1" "$2"
}

download_app() {
  local app="$1"
  local url="$2"
  local version

  macos_has "$app" || {
    if confirm "Do you want to download $app?"; then
      download_to "$url" ~/Downloads
      version=$(echo "$url" | getv)
      msg "Downloading $app $version."
    fi
  }
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
  local url
  local filename foldername
  local version current=

  if is_linux; then
    url=$(download_stdout https://github.com/neovim/neovim/releases/latest | grep -oP 'neovim/neovim/releases/download/v[0-9\.]+/nvim-linux64.tar.gz')
    foldername="nvim-linux64"
  else
    url=$(download_stdout https://github.com/neovim/neovim/releases/latest | grep -oE 'neovim/neovim/releases/download/v[0-9.]+/nvim-macos.tar.gz')
    foldername="nvim-osx64"
  fi
  version=$(echo "$url" | getv)
  program_exists nvim && current=$(nvim --version | getv)

  check_update "$current" "$version" "nvim" || {
    filename=$(parse "$url")
    download_to "github.com/$url" /tmp
    tar xzf "/tmp/$filename" -C /tmp
    rm -rf ~/.neovim
    mv "/tmp/$foldername" ~/.neovim
    rm "/tmp/$filename"
    lnif ~/.neovim/bin/nvim /usr/local/bin
  }
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
  if is_linux; then
    if [ -f /usr/bin/pip3 ]; then
      /usr/bin/pip3 install -U pynvim
    elif is_ubuntu; then
      sudo apt install -y python3-pip
    else
      warning "Install 'python3-pip' with your package manager."
    fi
  else
    if [ -f /usr/local/bin/pip3 ]; then
      /usr/local/bin/pip3 install -U pynvim
    else
      warning "Run 'brew install python'"
    fi
  fi
  lnif "$HOME/.vim"     "$HOME/.config/nvim"
  lnif "$HOME/.vimrc"   "$HOME/.config/nvim/init.vim"

  success "Setting up neovim."
}

setup_vim_plug() {
  program_exists vim || return 0

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
  is_linux || return 0
  local dest="$HOME/.config/i3"

  safe_mkdir "$dest"

  local ff
  for ff in "$app_path"/i3/*; do
    lnif "$ff" "$dest"
  done

  success "Now configuring i3wm."
}

config_ssh() {
  local target
  safe_mkdir ~/.ssh

  if is_personal; then
    for ff in "$app_path"/ssh/*.gpg; do
      target=$(basename "$ff" .gpg)
      safe_gpgdec "$ff" "$HOME/.ssh/$target"
    done
    cpif "$app_path/ssh/id_rsa.pub" ~/.ssh
  fi

  if [ -n "${AUTH_USERS:-}" ]; then
    read -ra users <<< "$AUTH_USERS"

    for user in "${users[@]}"; do
      add_auth_key "$user"
    done
  fi

  success "Now configuring ssh."
}

config_gpg() {
  if program_exists gpg; then
    local gpg_home="$HOME/.gnupg"
    safe_mkdir "$gpg_home"
    chmod 700 "$gpg_home"
    lnif "$app_path/gpg/gpg.conf" "$gpg_home"

    success "Now configuring gpg."
  fi
}

install_git_lfs() {
  is_macos || return 0

  local url
  local filename
  local version current=

  url=$(download_stdout https://github.com/git-lfs/git-lfs/releases | grep -o 'git-lfs/.*git-lfs-darwin.*.zip' | head -n1)
  version=$(echo "$url" | getv)
  program_exists git-lfs && current=$(git-lfs --version | getv)

  check_update "$current" "$version" "git-lfs" || {
    download_to "github.com/$url" /tmp
    filename=$(parse "$url")
    unzip "/tmp/$filename" -d /tmp/git-lfs
    cpif /tmp/git-lfs/git-lfs /usr/local/bin
    rm -rf "/tmp/$filename" /tmp/git-lfs
  }
}

config_git() {
  lnif "$app_path/git/hooks" ~/.githooks

  install_git_lfs

  # this is personal
  if is_personal; then
    msg "Setting personal git config."
    lnif "$app_path/git/config" ~/.gitconfig
  fi
}

config_hhkb() {
  local target="/usr/share/X11/xkb/symbols/pc"

  if [ -f "$target" ]; then
    insert_after_matching "Beginning" "\    modifier_map Control{ Henkan_Mode };" "$target"
    insert_after_matching "Beginning" "\    modifier_map Mod4   { Muhenkan };"    "$target"
    # sudo rm -rf /var/lib/xkb/*
    success "Now configuring HHKB keyboard."
  fi
}

config_homebrew() {
  is_macos || return 0

  local owner
  for ff in /usr/local/*; do
    owner=$(stat -f '%Su' "$ff")
    break
  done
  if [ "$owner" != "$USER" ]; then
    msg "Preparing disk permissions for Homebrew."
    sudo chown -R "$USER" /usr/local/*
  fi
}

install_shellcheck() {
  local url
  local filename foldername
  local version current=

  if is_linux; then
    url=$(download_stdout https://github.com/koalaman/shellcheck/releases | grep -o 'koalaman.*linux.x86_64.tar.xz' | head -n1)
  else
    url=$(download_stdout https://github.com/koalaman/shellcheck/releases | grep -o 'koalaman.*darwin.x86_64.tar.xz' | head -n1)
  fi
  version=$(echo "$url" | getv)
  program_exists shellcheck && current=$(shellcheck --version | grep version | getv)

  check_update "$current" "$version" "shellcheck" || {
    filename=$(parse "$url")
    if is_linux; then
      foldername=$(basename "$filename" .linux.x86_64.tar.xz)
    else
      foldername=$(basename "$filename" .darwin.x86_64.tar.xz)
    fi
    download_to "github.com/$url" /tmp
    tar xJf "/tmp/$filename" -C /tmp
    cpif "/tmp/$foldername/shellcheck" /usr/local/bin
    rm -rf "/tmp/$foldername" "/tmp/$filename"
  }
}

install_clangd() {
  local url
  local filename
  local version current=

  if is_macos && [ ! -f /usr/bin/clangd ]; then
    url=$(download_stdout https://github.com/clangd/clangd/releases/latest | grep -oE 'clangd/clangd/releases/download/[0-9.]+/clangd-mac-[0-9.]+.zip')
    version=$(echo "$url" | getv)
    program_exists clangd && current=$(clangd --version | getv)

    check_update "$current" "$version" "clangd" || {
      filename=$(parse "$url")
      download_to "github.com/$url" /tmp
      unzip "/tmp/$filename" -d /tmp >/dev/null
      cpif "/tmp/clangd_$version/bin/clangd" /usr/local/bin
      rm -rf /tmp/clangd*
    }
  fi
}

install_gpg() {
  is_macos || return 0
  local url
  local filename
  local version current=

  url=$(download_stdout https://sourceforge.net/p/gpgosx/docu/Download/ | grep -oE 'https://sourceforge.net/projects/gpgosx/files/GnuPG-[0-9.]+.dmg/download' | head -n1)
  version=$(echo "$url" | getv)
  program_exists gpg && current=$(gpg --version | getv)

  check_update "$current" "$version" "gpg" || {
    download_to "$url" ~/Downloads "GnuPG-$version.dmg"
  }
}

install_swiftlint() {
  program_exists unzip || {
    warning "Install unzip to extract zip files."
    return 0
  }

  local url
  local filename
  local version current=

  if is_linux; then
    url=$(download_stdout https://github.com/realm/SwiftLint/releases | grep -o 'realm/.*swiftlint_linux.zip' | head -n1)
  else
    url=$(download_stdout https://github.com/realm/SwiftLint/releases | grep -o 'realm/.*portable_swiftlint.zip' | head -n1)
  fi
  version=$(echo "$url" | getv)
  program_exists swiftlint && current=$(swiftlint --version | getv)

  check_update "$current" "$version" "swiftlint" || {
    download_to "github.com/$url" /tmp
    filename=$(parse "$url")
    unzip "/tmp/$filename" -d /tmp/swiftlint
    cpif /tmp/swiftlint/swiftlint /usr/local/bin
    rm -rf "/tmp/$filename" /tmp/swiftlint
  }
}

install_swiftformat() {
  is_macos || return 0

  local url
  local filename
  local version current=

  url=$(download_stdout https://github.com/nicklockwood/SwiftFormat/releases | grep -o 'nicklockwood/.*swiftformat.zip' | head -n1)
  version=$(echo "$url" | getv)
  program_exists swiftformat && current=$(swiftformat --version | getv)

  check_update "$current" "$version" "swiftformat" || {
    download_to "github.com/$url" /tmp
    filename=$(parse "$url")
    program_exists unzip || {
      warning "Install unzip to extract zip files."
      return 0
    }
    unzip "/tmp/$filename" -d /tmp/swiftformat
    cpif /tmp/swiftformat/swiftformat /usr/local/bin
    rm -rf "/tmp/$filename" /tmp/swiftformat
  }
}

optional_downloads() {
  is_macos || return 0
  local url

  url=$(download_stdout https://github.com/p0deje/Maccy/releases | grep -o 'p0deje/.*Maccy.app.zip' | head -n1)
  download_app Maccy "github.com/$url"

  url=$(download_stdout https://freemacsoft.net/appcleaner/ | grep -o 'https.*AppCleaner.*.zip' | head -n1)
  download_app AppCleaner "$url"
}

install_utils() {
  install_shellcheck
  install_clangd
  install_gpg
  install_swiftlint
  install_swiftformat
  optional_downloads
}

common_config_zsh() {
  local ff target

  lnif "$app_path/common" "$HOME/.common"

  [ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin
  for ff in "$app_path"/bin/*; do
    lnif "$ff" /usr/local/bin
  done

  if is_personal; then
    for ff in "$app_path"/zsh/*.gpg; do
      gpgdec "$ff" "$app_path/zsh/$(basename "$ff" .gpg)"
    done
    success "Private zshrc setup."

    for ff in "$app_path"/zsh/kaggle/*.gpg; do
      target="$app_path/zsh/kaggle/$(basename "$ff" .gpg)"
      safe_gpgdec "$ff" "$target"
    done
  fi

  for ff in "$app_path"/zsh/*; do
    if [[ "$ff" != *zinit* ]]; then
      lnif "$ff" "$HOME/.$(parse "$ff")"
    fi
  done

  # set ibus for archlinux
  if program_exists pacman; then
    append_if_not_exists "$HOME/.profile" "ibus-daemon -drx"
  fi

  config_i3wm
  config_ssh
  config_gpg
  config_git
  config_hhkb
  config_homebrew
  install_utils
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
    "pip"
    "jedi"
    "flake8"
    "mypy"
    "yapf"
    "virtualenv"
    "youtube-dl"
  )

  if [ ! -d "$conda" ]; then
    local url
    if is_wsl; then
      url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    elif is_linux; then
      url=$(download_stdout https://conda.io/miniconda.html | grep -o 'https.*Linux-x86_64.sh' | head -n1)
    else
      url=$(download_stdout https://conda.io/miniconda.html | grep -o 'https.*MacOSX-x86_64.sh' | head -n1)
    fi
    # shellcheck disable=SC2236
    if [ ! -z "$url" ]; then
      local miniconda
      miniconda=$(parse "$url")
      local target="/tmp"
      [ -f "$target/$miniconda" ] || download_to "$url" "$target"
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

  # this is personal
  if is_personal; then
    msg "Setting personal python packages."
    "$conda"/bin/pip install -U beancount fava
  fi
}

install_golang() {
  local url
  local current version
  local filename
  local goroot="$HOME/.golang"

  if is_linux; then
    url=$(download_stdout https://golang.org/dl/ | grep -oP '\/dl\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n1)
  else
    url=$(download_stdout https://golang.org/dl/ | grep -oE '/dl/go[0-9.]+.darwin-amd64.pkg' | head -n1)
  fi
  version=$(echo "$url" | getv)
  filename=$(parse "$url")

  if program_exists go; then
    current=$(go version | getv)
  elif [ -f "$goroot/VERSION" ]; then
    current=$(getv < "$goroot/VERSION")
  fi

  check_update "$current" "$version" "Go" || {
    if is_linux; then
      [ -f "/tmp/$filename" ] || download_to "https://golang.org$url" "/tmp"
      tar xzf "/tmp/$filename" -C /tmp
      cp -Tr /tmp/go "$goroot"
      rm -rf "/tmp/$filename" /tmp/go
    else
      download_to "https://golang.org$url" ~/Downloads
    fi
  }
}

install_node() {
  local node_home="$HOME/.node"
  local url
  local current version
  local filename

  if is_linux; then
    url=$(download_stdout https://nodejs.org/en/download/ | grep -oP 'https:\/\/nodejs\.org\/dist\/v([0-9\.]+)/node-v([0-9\.]+)-linux-x64\.tar\.xz')
  else
    url=$(download_stdout https://nodejs.org/en/download/ | grep -oE 'https://nodejs.org/dist/v[0-9.]+/node-v[0-9.]+-darwin-x64.tar.gz')
  fi
  version=$(echo "$url" | getv)
  filename=$(parse "$url")

  if program_exists node; then
    current=$(node -v | getv)
  elif [ -f "$node_home/bin/node" ]; then
    current=$("$node_home/bin/node" -v | getv)
  fi

  check_update "$current" "$version" "Node.js" || {
    [ -f "/tmp/$filename" ] || download_to "$url" "/tmp"
    local node
    if is_linux; then
      tar xJf "/tmp/$filename" -C /tmp
      node="$(basename "$filename" .tar.xz)"
    else
      tar xzf "/tmp/$filename" -C /tmp
      node="$(basename "$filename" .tar.gz)"
    fi
    rm -rf "$node_home" "/tmp/$filename"
    mv "/tmp/$node" "$node_home"
  }
}

install_java() {
  local url
  local filename
  local jdk="$HOME/.jdk"

  [ -d "$jdk" ] && return 0
  mkdir "$jdk"
  msg "Installing openjdk-16"

  if is_linux; then
    url=$(download_stdout https://jdk.java.net/16/ | grep -o 'https.*linux-x64_bin.tar.gz' | head -n1)
  else
    url=$(download_stdout https://jdk.java.net/16/ | grep -o 'https.*osx-x64_bin.tar.gz' | head -n1)
  fi
  filename=$(parse "$url")
  download_to "$url" /tmp
  tar xzf "/tmp/$filename" -C "$jdk"
  rm "/tmp/$filename"
}

install_swift() {
  is_ubuntu || return 0
  local current version
  local url filename
  local swift="$HOME/.swift"
  [ -d "$swift" ] && return 0
  mkdir "$swift"

  url=$(download_stdout "https://swift.org/download/#releases" | grep -o 'builds/.*RELEASE-ubuntu20.04.tar.gz' | head -n1)
  url="https://swift.org/$url"
  version=$(echo "$url" | getv)
  filename=$(parse "$url")

  if [ -f "$swift/usr/bin/swift" ]; then
    current=$("$swift"/usr/bin/swift --version | getv)
  fi
  check_update "$current" "$version" "Swift" || {
    [ -f "/tmp/$filename" ] || download_to "$url" "/tmp"
    tar xzf "/tmp/$filename" -C /tmp
    local extracted
    extracted="$(basename "$filename" .tar.gz)"
    cp -r /tmp/"$extracted"/* "$swift"
    rm -rf "/tmp/$filename" "/tmp/$extracted"
  }
}

install_docker() {
  # don't run on CI, non-ubuntu os and within docker
  is_not_ci || return 0
  is_ubuntu || return 0
  is_docker && return 0

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
      download_stdout https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
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

  local current version
  version="$(download_stdout https://github.com/docker/compose/releases | grep -oP '\d+(\.\d+)+/docker-compose-Linux' | head -n1 | getv)"
  program_exists docker-compose && current="$(docker-compose --version | getv)"

  check_update "$current" "$version" "Docker-compose" || {
    local target="/usr/local/bin/docker-compose"
    sudo curl -L "https://github.com/docker/compose/releases/download/$version/docker-compose-$(uname -s)-$(uname -m)" -o "$target"
    msg "Making it executable."
    sudo chmod +x "$target"
    success "Now installing Docker Compose."
  }
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
  git_pull "$rbenv"/plugins/ruby-build
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
