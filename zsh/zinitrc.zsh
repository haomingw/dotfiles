# setopt prompt_subst

source ~/.zinit/zinit.zsh

zinit wait lucid for \
    rupa/z \
    ~/.zsh/plugins \
    zdharma-continuum/fast-syntax-highlighting

### --- OMZ snippets (only what matters) ---
zinit snippet OMZ::lib/git.zsh
zinit snippet OMZ::lib/key-bindings.zsh
zinit snippet OMZ::lib/async_prompt.zsh
zinit snippet OMZ::lib/theme-and-appearance.zsh
zinit snippet OMZ::lib/completion.zsh

# Optional: only if you really need them
# zinit snippet OMZ::lib/history.zsh

zinit light-mode for \
  zsh-users/zsh-autosuggestions \
  zdharma-continuum/history-search-multi-word

autoload -Uz compinit
compinit
zi cdreplay -q

safe_source ~/.zsh/themes/xpure.zsh

safe_source ~/.zshrc.local
