#!/usr/bin/env bash
set -e

if [[ "$(uname)" == "Linux" ]]; then
  app=$(dirname "$(readlink -f "$0")")
else
  app=$(dirname "$PWD/$0")
fi

# shellcheck disable=SC1090,SC1091
source "$app/common/functions"

check_os() {
  case "$(uname)" in
    "Linux") ;;
    "Darwin") ;;
    *) echo "Only *nix is supported for now."; return 1;;
  esac
}

check_bash_version() {
  local bv
  bv=$(bash --version | getv)
  if check_version "$bv" "<" "$1"; then
    echo "Mininum bash version is $1, current: $bv"
    return 1
  fi
}

check_os
check_bash_version 4

# for small repos
mirrors=(
  "https://github.com/junegunn/vim-plug.git"
)
sources=(
  "plug.vim"
)
targets=(
  "vim/vim/autoload/plug.vim"
)

# for large repos
clang_format="vim/vim/static/clang-format.py"
tldr_sh="bin/tldr"
zsh_aync="zsh/zsh/async.zsh"

declare -A files=(
  ["$clang_format"]="https://raw.githubusercontent.com/llvm/llvm-project/\
main/clang/tools/clang-format/clang-format.py"
  ["$tldr_sh"]="https://raw.githubusercontent.com/raylee/tldr/master/tldr"
  ["$zsh_aync"]="https://raw.githubusercontent.com/mafredri/zsh-async/master/async.zsh"
)

get_filename() {
  echo "$1" | rev | cut -d'/' -f1 | rev | cut -d'.' -f1
}

git_check_file() {
  pushd "$app" >/dev/null
  local target="$1"
  local message="$2"
  local changes
  changes=$(git diff "$target")

  if [ -z "$changes" ]; then
    echo "No changes for $target"
  else
    echo "Committing changes of $target"
    git add "$target"
    git commit -m "$message"
  fi
  popd >/dev/null
}

update_target() {
  local mirror="$1"
  local from="$2"
  local to="$3"

  local name
  name=$(get_filename "$mirror")
  if [ ! -d ~/.mirrors/"$name" ]; then
    git clone "$mirror" ~/.mirrors/"$name"
  fi
  pushd ~/.mirrors/"$name" >/dev/null
  git pull

  if [ "$name" = git-secret ]; then
    make build
  fi

  local msg
  msg=$(git show -s --format=%s)
  cp "$from" "$app/$to"
  git_check_file "$to" "[$name] $msg"
  popd >/dev/null
}

mirror_small() {
  local i=0
  for mirror in "${mirrors[@]}"; do
    update_target "$mirror" "${sources[$i]}" "${targets[$i]}"
    ((i+=1))
  done
}

mirror_large() {
  local name

  for target_file in "${!files[@]}"; do
    name=$(get_filename "$target_file")
    curl -fsSL "${files[$target_file]}" > "$app/$target_file"
    git_check_file "$target_file" "[$name] Mirror update"
  done
}

main() {
  mirror_small
  mirror_large
}

main
