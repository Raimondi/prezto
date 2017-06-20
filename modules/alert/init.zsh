# After a command finishes execute an "alert" command if it took too long.
_alert_start_time=${_alert_start_time=$SECONDS}
_alert_cmd=${_alert_cmd=}

function _alert_preexec() {
  local max_len
  zstyle -s ':prezto:module:alert' max_len 'max_len' \
    && [[ $max_len -gt 0 ]] \
    || max_len=30
  _alert_start_time=$SECONDS
  _alert_cmd=${2:0:$max_len}
}
function _alert_precmd() {
  local time_limit alert ignored elapsed_time modifiers cmd

  elapsed_time=$(($SECONDS - $_alert_start_time))
  modifiers=(builtin command nocorrect noglob -)
  cmd=$_alert_cmd
  _alert_cmd=
  zstyle -s ':prezto:module:alert' time 'time_limit' \
    || time_limit=5
  zstyle -s ':prezto:module:alert' ignored 'ignored' \
    || ignored=( vi vim gvim less man nano more view
         gview ex ed vimtutor emacs ssh)
  # Not long enough or empty command.
  if [[ $elapsed_time -lt $time_limit || ! -n $cmd ]]; then
    return
  fi
  # Remove modifiers.
  len=${#modifiers}
  while [[ $len -gt ${#${modifiers#${cmd%% *}}} ]]; do
    cmd=${cmd#* }
  done
  # Return if the command is in the ignored list.
  if [[ ${#ignored} -gt ${#${ignored#${${cmd#sudo }%% *}}} ]]; then
    return
  fi
  zstyle -s ':prezto:module:alert' alert 'alert' \
    || alert='whence osascript &>/dev/null && osascript -e "display notification \"The command, %c, has finished.\""'
  zformat -f alert $alert c:'$cmd'
  eval $alert
}

add-zsh-hook preexec _alert_preexec
add-zsh-hook precmd  _alert_precmd
