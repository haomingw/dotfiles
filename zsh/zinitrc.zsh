start=$(now)
setopt prompt_subst

source ~/.zinit/zinit.zsh

zinit wait lucid for \
    rupa/z \
    OMZ::lib/completion.zsh \
    OMZ::plugins/git/git.plugin.zsh \
  atinit"ZINIT[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay" \
    zdharma/fast-syntax-highlighting

zinit light-mode for \
  zsh-users/zsh-autosuggestions \
  zdharma/history-search-multi-word \
  OMZ::lib/git.zsh \
  OMZ::lib/history.zsh \
  OMZ::lib/key-bindings.zsh \
  OMZ::lib/theme-and-appearance.zsh

safe_source ~/.zsh/themes/xpure.zsh

safe_source ~/.zshrc.local

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

if [[ -n "$start" ]]; then
  dur=$(echo "$(now) - $start" | bc)
  printf "Execution time: %.6f seconds\n" "$dur"
fi
