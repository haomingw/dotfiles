#!/usr/bin/env bash

APP_PATH="$(dirname "$PWD/$0")"

for file in "$APP_PATH"/common/*; do
  # shellcheck disable=SC1090,SC1091
  source "$file"
done

clang_format="vim/vim/static/clang-format.py"
vim_plug="vim/vim/autoload/plug.vim"

declare -A files=(
  ["$clang_format"]="https://raw.githubusercontent.com/llvm/llvm-project/\
master/clang/tools/clang-format/clang-format.py"
  ["$vim_plug"]="https://raw.githubusercontent.com/junegunn/vim-plug/\
master/plug.vim"
)

for file in "${!files[@]}"; do
  msg "Updating $file"
  curl -fsSL "${files[$file]}" > "$APP_PATH/$file"
done
