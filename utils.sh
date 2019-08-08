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
    program_exists $1

    # throw error on non-zero return value
    if [ $? -ne 0 ]; then
        error "You must have '$1' installed to continue."
    fi
}

file_must_exist() {
    local file_path="$1"

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
    local git_url="$1"
    local target_path="$2"
    local repo_name=`echo ${git_url##*/} | cut -d'.' -f1`

    if [ -d $target_path ] && [ ! -d target_path/$repo_name ]; then
        cd $target_path && git clone $git_url
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

create_symlinks() {
    local source_path="$1"

    copy "$source_path/vim"       "$HOME/.vim"
    lnif "$source_path/vim/vimrc" "$HOME/.vimrc"

    success "Setting up vim symlinks."
}

update_repo() {
    git stash
    git pull

    success "Updating repository."
}
