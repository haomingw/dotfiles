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
    # fail on non-zero return value
    command -v $1 >/dev/null 2>&1 || return 1
    return 0
}

program_must_exist() {
    program_exists $1

    # throw error on non-zero return value
    if [ "$?" -ne 0 ]; then
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
        msg "Attempting to back up your original configuration."
        today=`date +%Y%m%d_%s`
        [ -e "$1" ] && [ ! -L "$1" ] && mv -v "$1" "$1.$today";
        ret="$?"
        success "Your original configuration has been backed up."
        debug
   fi
}

create_symlinks() {
    local source_path="$1"

    copy "$source_path/vim"       "$HOME/.vim"
    lnif "$source_path/vim/vimrc" "$HOME/.vimrc"

    config_nvim_if_exists

    ret="$?"
    success "Setting up vim symlinks."
    debug
}

config_nvim_if_exists() {
    if program_exists "nvim" && [ ! -d $HOME/.config/.nvim ]; then
        mkdir -p $HOME/.config
        lnif "$HOME/.vim"         "$HOME/.config/nvim"
        lnif "$HOME/.vimrc"       "$HOME/.config/nvim/init.vim"
    fi
}
