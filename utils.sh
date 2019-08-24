############################  BASIC SETUP TOOLS
msg() {
    printf '%b\n' "$1" >&2
}

success() {
    msg "\33[32m[✔]\33[0m ${1}${2}"
}

err() {
    msg "\33[31m[✘]\33[0m ${1}${2}"
}

error() {
    err "$@"
    exit 1
}

program_exists() {
    # fail on non-zero return value
    command -v $1 >/dev/null 2>&1 && return 0 || return 1
}

is_linux() {
    [ $(uname) == "Linux" ] && return 0 || return 1
}

is_macos() {
    [ $(uname) == "Darwin" ] && return 0 || return 1
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

update_repo() {
    git stash
    git pull

    success "Updating repository."
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
    find $HOME/miniconda3 \( -type f -o -type l \) -not -path "$HOME/miniconda3/pkgs*" -regex ".*bin/wish[0-9\.]*$" -ls -delete
    success "Cleaning up minconda files"
}

install_miniconda_if_not_exists() {
    if [ ! -d $HOME/miniconda3 ]; then
        local url
        is_linux && url='https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh'
        is_macos && url='https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh'
        if [ ! -z "$url" ]; then
            local miniconda=$(echo $url | rev | cut -d'/' -f1 | rev)
            local target="$HOME/Downloads"
            [ -f "$target/$miniconda" ] || wget $url -P $target
            bash $target/$miniconda \
            && success "Miniconda successfully installed" \
            && cleanup_miniconda_files $target/$miniconda
        fi
    fi
}
