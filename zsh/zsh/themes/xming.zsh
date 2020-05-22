source $HOME/.zsh/async.zsh

make_arrow() {
  local arrows=' ' left=${1:-0} right=${2:-0}

  (( right > 0 )) && arrows+=⇣
  (( left > 0 )) && arrows+=⇡

  [[ -z ${arrows// } ]] || echo $arrows
}

prompt_git_fetch() {
  git rev-parse --is-inside-work-tree &>/dev/null && {
    local ref=$(git symbolic-ref -q HEAD)
    local remote=($(git for-each-ref --format='%(upstream:remotename) %(refname)' $ref))
    git fetch $remote && {
      local x=$(git rev-list --left-right --count HEAD...@'{u}')
      make_arrow ${(ps:\t:)x}
    }
  }
}

prompt_refresh() {
  zle && zle .reset-prompt
}

prompt_callback() {
  local job=$1 code=$2 output=$3 exec_time=$4
  case $job in
    \[async])
      # handle all the errors
      if (( code == 2 )) || (( code == 3 )) || (( code == 130 )); then
        prompt_async_inited=0
        async_stop_worker 'prompt'
        prompt_async_init
      fi
      ;;
    prompt_git_fetch) git_arrow=$output ;;
  esac
  prompt_refresh
}

prompt_precmd() {
  print -Pn '\e]0;%~\a'
  async_worker_eval 'prompt' builtin cd -q $PWD
  async_job 'prompt' prompt_git_fetch
}

prompt_async_init() {
  if ((${prompt_async_inited:-0})); then
    return
  fi
  prompt_async_inited=1

  async_init
  async_start_worker 'prompt' -u -n
  async_register_callback 'prompt' prompt_callback
}

prompt_setup() {
  zmodload zsh/zle
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd prompt_precmd

  typeset -g prompt_async_inited
  typeset -g git_arrow

  prompt_async_init

  PROMPT='%B%F{cyan}%c%f%b$(git_prompt_info)%B%F{blue}$git_arrow%f%b %(?.%F{green}.%F{red})❯%f '

  ZSH_THEME_GIT_PROMPT_PREFIX=" %F{242}"
  ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
  ZSH_THEME_GIT_PROMPT_DIRTY="%F{yellow}*"
  ZSH_THEME_GIT_PROMPT_CLEAN=""
}

prompt_setup "$@"
