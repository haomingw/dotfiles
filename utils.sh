############################  BASIC SETUP TOOLS
msg() {
    printf '%b\n' "$1" >&2
}

success() {
    if [ "$ret" -eq '0' ]; then
        msg "\33[32m[✔]\33[0m ${1}${2}"
    fi
}

error() {
    msg "\33[31m[✘]\33[0m ${1}${2}"
    exit 1
}

debug() {
    if [ "$debug_mode" -eq '1' ] && [ "$ret" -gt '1' ]; then
        msg "An error occurred in function \"${FUNCNAME[$i+1]}\" on line ${BASH_LINENO[$i+1]}, we're sorry for that."
    fi
}

program_exists() {
    local ret='0'
    command -v $1 >/dev/null 2>&1 || { local ret='1'; }

    # fail on non-zero return value
    if [ "$ret" -ne 0 ]; then
        return 1
    fi

    return 0
}

program_must_exist() {
    program_exists $1

    # throw error on non-zero return value
    if [ "$?" -ne 0 ]; then
        error "You must have '$1' installed to continue."
    fi
}

lnif() {
    if [ -e "$1" ]; then
        ln -sf "$1" "$2"
    fi
    ret="$?"
    debug
}

copy() {
    if [ -e "$1" ]; then
        cp -r "$1" "$2"
    fi
    ret="$?"
    debug
}

git_clone_to() {
    local git_url=$1
    local target_path=$2
    local repo_name=`echo ${git_url##*/} | cut -d'.' -f1`
    if [ -d $target_path ] && [ ! -d target_path/$repo_name ]; then
        cd $target_path && git clone $git_url
    fi
    ret="$?"
    debug
}

############################ SETUP FUNCTIONS

do_backup() {
    if [ -e "$1" ]; then
        msg "Attempting to back up your original vim configuration."
        today=`date +%Y%m%d_%s`
        [ -e "$1" ] && [ ! -L "$1" ] && mv -v "$1" "$1.$today";
        ret="$?"
        success "Your original vim configuration has been backed up."
        debug
   fi
}

create_symlinks() {
    local source_path="$1"
    local target_path="$2"

    copy "$source_path/vim"           "$target_path/.vim"
    lnif "$source_path/vimrc"         "$target_path/.vimrc"

    if program_exists "nvim"; then
        lnif "$source_path/vim"       "$target_path/.config/nvim"
        copy "$source_path/vimrc"     "$target_path/.config/nvim/init.vim"
    fi

    ret="$?"
    success "Setting up vim symlinks."
    debug
}

setup_vim_plug() {
    local system_shell="$SHELL"
    export SHELL='/bin/sh'

    vim +PlugInstall +qall

    export SHELL="$system_shell"

    success "Now updating/installing plugins using vim-plug"
    debug
}

post_install_vim() {
    local ret='0'
    mkdir -p ~/.vim/undo
    success "Postpone installation finished."
    debug
}

install_oh_my_zsh() {
    [ ! -d "$HOME/.oh-my-zsh" ] && sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    success "oh my zsh installed"
}

install_zsh_plugins() {
    local plugin_path=$1
    git_clone_to https://github.com/zsh-users/zsh-autosuggestions.git       $plugin_path
    git_clone_to https://github.com/zsh-users/zsh-syntax-highlighting.git   $plugin_path
    success "Now installing zsh plugins."
}

setup_zsh() {
    local source_path="$1"
    local target_path="$2"

    copy "$source_path/zshrc" "$target_path/.zshrc"
    success "Setting up zsh configuration file."
}
