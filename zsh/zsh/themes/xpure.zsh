git_arrows() {
  # Only run inside a git repo
  git rev-parse --is-inside-work-tree &>/dev/null || return

  # Get ahead/behind counts
  local ahead behind
  read ahead behind <<< $(git rev-list --left-right --count HEAD..."@{upstream}" 2>/dev/null)

  local arrows

  (( ahead > 0 )) && arrows+="⇡"
  (( behind > 0 )) && arrows+="⇣"

  [[ -n "$arrows" ]] && echo " $arrows"
}

prompt_setup() {
  PROMPT='%B%F{cyan}%c%f%b$(git_prompt_info)%B%F{blue}$(git_arrows)%f%b %(?.%F{green}.%F{red})❯%f '

  ZSH_THEME_GIT_PROMPT_PREFIX=" %F{magenta}"
  ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
  ZSH_THEME_GIT_PROMPT_DIRTY="%F{yellow}*"
  ZSH_THEME_GIT_PROMPT_CLEAN=""
}

prompt_setup "$@"
