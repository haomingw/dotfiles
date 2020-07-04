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

[[ -s ~/.zsh/themes/xpure.zsh ]] && source ~/.zsh/themes/xpure.zsh

[[ -s $HOME/.zshrc.local ]] && source $HOME/.zshrc.local

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
