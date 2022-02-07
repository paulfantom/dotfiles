# paulfantom.zsh-theme
#
# Author: Paweł Krupa
# URL: https://github.com/paulfantom

# primary prompt: dashed separator, directory and k8s info
PS1="${FG[237]}\${(l.\$COLUMNS..-.)}%{$reset_color%}
${FG[032]}%~\$(git_prompt_info)\$(hg_prompt_info) ${FG[105]}%(!.#.»)%{$reset_color%} "
PS2="%{$fg[red]%}\ %{$reset_color%}"

# right prompt: return code, k8s and context (user@host)
RPS1="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"
if (( $+functions[kube_ps1] )); then
  RPS1+=' $(kube_ps1)'
fi
RPS1+=" ${FG[237]}%n@%m%{$reset_color%}"

# git settings
ZSH_THEME_GIT_PROMPT_PREFIX=" ${FG[075]}(${FG[078]}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="${FG[214]}*%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="${FG[075]})%{$reset_color%}"

# kube ps1 settings
KUBE_PS1_SYMBOL_ENABLE=false
