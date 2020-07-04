source ~/.zinit/zinit.zsh

setopt prompt_subst

zinit wait lucid for \
    rupa/z \
    zdharma/history-search-multi-word \
    OMZ::lib/completion.zsh \
    OMZ::lib/key-bindings.zsh \
    OMZ::lib/theme-and-appearance.zsh \
    OMZ::plugins/git/git.plugin.zsh \
  atinit"ZINIT[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay" \
    zdharma/fast-syntax-highlighting

zinit light-mode for \
  zsh-users/zsh-autosuggestions \
  OMZ::lib/git.zsh \
  OMZ::lib/history.zsh

# [[ -s $HOME/.zshrc.local ]] && source $HOME/.zshrc.local

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
