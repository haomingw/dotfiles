############################  BASIC SETUP TOOLS

for file in common/*; do
    source $file
done

msg() {
    printf '%b\n' "$1" >&2
}

program_must_exist() {
    program_exists "$1" || {
        error "You must have '$1' installed to continue."
        exit 1
    }
}

file_must_exist() {
    local file_path=$1

    if [ ! -f "$file_path" ] && [ ! -d "$file_path" ]; then
        error "You must have '$1' to continue."
        exit 1
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
    local app=$1

    mkdir -p $HOME/.vim/undo
    for file in $app/vim/vim/*; do
        lnif $file "$HOME/.vim/$(parse $file)"
    done
    lnif "$app/vim/vimrc"                   "$HOME/.vimrc"
    lnif "$app/vim/ideavimrc"               "$HOME/.ideavimrc"

    lnif "$app/vim/vim/static/clang-format" "$HOME/.clang-format"
    lnif "$app/vim/vim/static/style.yapf"   "$HOME/.style.yapf"

    success "Setting up vim symlinks."
}

setup_neovim() {
    mkdir -p $HOME/.config
    lnif "$HOME/.vim"         "$HOME/.config/nvim"
    lnif "$HOME/.vimrc"       "$HOME/.config/nvim/init.vim"
    success "Setting up neovim."
}

setup_vim_plug() {
    local system_shell="$SHELL"
    export SHELL='/bin/sh'

    vim +PlugClean! +qall && vim +PlugUpdate +qall

    export SHELL="$system_shell"

    success "Now updating/installing plugins using vim-plug"
}

use_zsh_plugin() {
    local pattern="^\s*$1$"
    local target="$HOME/.zshrc"
    grep -q $pattern $target || {
        sed -i "/^plugins=/a \    $1" $target
    }
}

use_zsh_plugins() {
    for plugin in "$@"; do
        use_zsh_plugin $plugin
    done
}

install_community_plugins() {
    local plugin_path

    for plugin in "$@"; do
        plugin_path="$ZSH_CUSTOM/plugins"

        if [ ! -d "$plugin_path/$plugin" ]; then
            git_clone_to https://github.com/zsh-users/$plugin.git $plugin_path
            use_zsh_plugin $plugin
            success "Now installing zsh plugin $plugin."
        fi
    done
}

append_if_not_exists() {
    local file=$1
    local content=$2
    if [ ! -f $file ] || ! $(grep -q "$content" $file); then
        echo $content >> $file
    fi
}

config_zshrc() {
    local app_path=$1
    local zshrc="$HOME/.zshrc"
    sed -i '/plugins=(git)/c \plugins=(\n    git\n)' $zshrc
    lnif $app_path/common                 $HOME/.common
    for file in $app_path/zsh/*; do
        lnif $file "$HOME/.$(parse $file)"
    done
    local cmd='[[ -s $HOME/.zshrc.local ]] && source $HOME/.zshrc.local'
    append_if_not_exists $zshrc "$cmd"

    # set ibus for archlinux
    program_exists pacman && {
        cmd='ibus-daemon -drx'
        append_if_not_exists $HOME/.profile "$cmd"
    }

    success "Now configuring zsh."
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
    program_exists pacman && cfg="/etc/sysctl.d/50-max_user_watches.conf"
    local message=(
        "Do you want to increase (requires sudo password)"
        "inotify limit? (y/N) "
    )
    if [ ! -z $cfg ] && [ -r $cfg ]; then
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
        "eamodio.gitlens"
        "ms-python.python"
        "mitaki28.vscode-clang"
    )
    for extension in "${extensions[@]}"; do
        code --install-extension $extension
    done
    success "Vscode extensions are installed"
}
