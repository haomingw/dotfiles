start=$(now)
setopt prompt_subst

source ~/.zinit/zinit.zsh

zinit wait lucid for \
    rupa/z \
    OMZ::lib/completion.zsh \
    ~/.zsh/plugins \
  atinit"ZINIT[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay" \
    zdharma-continuum/fast-syntax-highlighting


zinit light-mode for \
  zsh-users/zsh-autosuggestions \
  OMZ::lib/async_prompt.zsh \
  OMZ::lib/git.zsh \
  OMZ::lib/history.zsh \
  OMZ::lib/key-bindings.zsh \
  zdharma-continuum/history-search-multi-word \
  OMZ::lib/theme-and-appearance.zsh

safe_source ~/.zsh/themes/xpure.zsh

safe_source ~/.zshrc.local

if [[ -n "$start" ]]; then
  dur=$(echo "$(now) - $start" | bc)
  printf "Execution time: %.6f seconds\n" "$dur"
fi
