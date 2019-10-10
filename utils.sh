############################  BASIC SETUP TOOLS
msg() {
    printf '%b\n' "$1" >&2
}

success() {
    msg "\033[32m[✔]\033[0m ${1}${2}"
}

err() {
    msg "\033[31m[✘]\033[0m ${1}${2}"
}

error() {
    err $@
    exit 1
}

program_exists() {
    # fail on non-zero return value
    command -v $1 >/dev/null 2>&1
}

is_linux() {
    [ $(uname) == "Linux" ]
}

is_macos() {
    [ $(uname) == "Darwin" ]
}

program_must_exist() {
    program_exists "$1"

    # throw error on non-zero return value
    if [ $? -ne 0 ]; then
        error "You must have '$1' installed to continue."
    fi
}

file_must_exist() {
    local file_path=$1

    if [ ! -f "$file_path" ] && [ ! -d "$file_path" ]; then
        error "You must have '$1' to continue."
    fi
}

lnif() {
    if [ -e "$1" ]; then
        ln -sf "$1" "$2"
    fi
}

copy() {
    if [ -e "$1" ]; then
        cp -r "$1" "$2"
    fi
}

git_clone_to() {
    local git_url=$1
    local target_path=$2
    local repo_name=$(basename "$git_url" .git)

    if [ -d "$target_path" ] && [ ! -d "$target_path/$repo_name" ]; then
        cd $target_path && git clone $git_url
    fi
}

insert_if_not_exists() {
    local pattern=$1
    local text=$2
    local target=$3
    if [ ! -f "$target" ] || ! $(grep -q "$pattern" "$target"); then
        echo $text >> $target
    fi
}

parse_filename() {
    echo $1 | rev | cut -d'/' -f1 | rev
}

############################ SETUP FUNCTIONS

do_backup() {
    if [ -e "$1" ]; then
        msg "Attempting to back up your original configuration."
        today=`date +%Y%m%d_%s`
        [ -e "$1" ] && [ ! -L "$1" ] && mv -v "$1" "$1.$today";
        success "Your original configuration has been backed up."
   fi
}

create_vim_symlinks() {
    local app_path=$1

    copy "$app_path/vim/dotvim" "$HOME/.vim"
    lnif "$app_path/vim/vimrc"  "$HOME/.vimrc"

    success "Setting up vim symlinks."
}

setup_vim_plug() {
    local system_shell="$SHELL"
    export SHELL='/bin/sh'

    vim +PlugUpdate +qall

    export SHELL="$system_shell"

    success "Now updating/installing plugins using vim-plug"
}

post_install_vim() {
    mkdir -p $HOME/.vim/undo
    success "Postpone installation finished."
}

install_zsh_plugin() {
    local plugin_name=$1
    local plugin_path="$ZSH_CUSTOM/plugins"

    if [ ! -d "$plugin_path/$plugin_name" ]; then
        git_clone_to https://github.com/zsh-users/$plugin_name.git $plugin_path
        sed -i "/^plugins=/a \    $plugin_name" $HOME/.zshrc
        success "Now installing zsh plugin $plugin_name."
    fi
}

config_zshrc() {
    local app_path=$1
    local zshrc="$HOME/.zshrc"
    sed -i '/plugins=(git)/c \plugins=(\n    git\n)' $zshrc
    lnif $app_path/zsh/zshrc.before.local $HOME/.zshrc.before.local
    lnif $app_path/zsh/zshrc.local        $HOME/.zshrc.local
    lnif $app_path/zsh/dotzsh             $HOME/.zsh
    local cmd='[[ -s $HOME/.zshrc.local ]] && source $HOME/.zshrc.local'
    insert_if_not_exists 'zshrc.local' "$cmd" $zshrc
    success "Now configuring zsh."
}

setup_nvim_if_exists() {
    if program_exists "nvim" && [ ! -d $HOME/.config/.nvim ]; then
        mkdir -p $HOME/.config
        lnif "$HOME/.vim"         "$HOME/.config/nvim"
        lnif "$HOME/.vimrc"       "$HOME/.config/nvim/init.vim"
        success "Setting up neovim."
    fi
}

cleanup_miniconda_files() {
    local installation_file=$1
    rm $installation_file
    find $HOME/miniconda3 \( -type f -o -type l \) \
        -not -path "$HOME/miniconda3/pkgs*" \
        -regex ".*bin/wish[0-9\.]*$" -ls -delete
    success "Cleaning up minconda files"
}

install_miniconda_if_not_exists() {
    if [ ! -d $HOME/miniconda3 ]; then
        local url
        local conda_repo="https://repo.anaconda.com/miniconda"
        is_linux && url="$conda_repo/Miniconda3-latest-Linux-x86_64.sh"
        is_macos && url="$conda_repo/Miniconda3-latest-MacOSX-x86_64.sh"
        if [ ! -z "$url" ]; then
            local miniconda=$(parse_filename $url)
            local target="$HOME/Downloads"
            [ -f "$target/$miniconda" ] || wget $url -P $target
            bash $target/$miniconda \
            && success "Miniconda successfully installed" \
            && cleanup_miniconda_files $target/$miniconda
        fi
    fi
}

watch_limit_is_increased() {
    program_exists sysctl && {
        local limit=$(sysctl fs.inotify.max_user_watches | cut -d' ' -f3)
        [ $limit -ge 524288 ]
    }
}

increase_watch_limit() {
    # if the limit has been increased, do nothing
    watch_limit_is_increased && return 0

    local watch_limit="fs.inotify.max_user_watches=524288"
    local cfg
    program_exists apt && cfg="/etc/sysctl.conf"
    program_exists pacman && cfg="/etc/sysctl.d/40-max-user-watches.conf"
    if [ ! -z $cfg ] && [ -r $cfg ]; then
        local message=(
            "Do you want to increase (requires sudo password)"
            "inotify limit? (y/N) "
        )
        read -p "${message[*]}"
        case $REPLY in
            [yY][eE][sS]|[yY]) ;;
            *) return 0 ;;
        esac
        cat $cfg | grep -q "$watch_limit" || {
            echo $watch_limit | sudo tee -a $cfg >/dev/null
        }
        program_exists apt && sudo sysctl -p >/dev/null
        program_exists pacman && sudo sysctl --system >/dev/null
        success "Increasing inotify watcher limit"
    fi
}

install_vscode_extensions() {
    extensions=(
        "ms-vscode.go"
        "ms-python.python"
        "mitaki28.vscode-clang"
    )
    for extension in "${extensions[@]}"; do
        code --install-extension $extension
    done
    success "Vscode extensions are installed"
}
