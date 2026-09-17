#!/bin/sh

# exit the script if any statement returns a non-true return value
set -e

unset SHELL

unset GREP_OPTIONS
export LC_NUMERIC=C
# shellcheck disable=SC3041
[ -n "${BASH_VERSION:-}" ] && set +H 2>/dev/null || true

_uname_s() {
  : "${__uname_s:=$(uname -s)}"
  printf '%s\n' "$__uname_s"
}

[ -z "$TMUX" ] && exit 255
if [ -z "$TMUX_SOCKET" ]; then
  # /path/to/socket,pid,session
  TMUX_SOCKET=${TMUX%%,*}
fi
TMUX_PROGRAM=@tmux_program@
TMUX_CONF=@tmux_conf@

tmux() {
  "$TMUX_PROGRAM" ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} "$@"
}

_is_true() {
  case "$1" in
    true|yes|1)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

_is_disabled() {
  [ "$1" = "disabled" ]
}

_pane_info() {
  pane_pid="$1"
  pane_tty="${2##/dev/}"
  case "$(_uname_s)" in
    *Linux*)
      ps -t "$pane_tty" --sort=lstart -o user=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -o pid= -o ppid= -o command= | awk -v pane_pid="$pane_pid" -v ssh="$(command -v ssh)" '
        ((/ssh/ && !/-W/ && !/tsh proxy ssh/ && !/sss_ssh_knownhostsproxy/) || !/ssh/) && !/(^|[[:space:]\/])tee([[:space:]]|$)/ {
          user[$2] = $1; if (!child[$3]) child[$3] = $2; pid=$2; $1 = $2 = $3 = ""; command[pid] = substr($0,4)
        }
        END {
          pid = pane_pid
          while (child[pid]) {
            if (match(command[pid], "^" ssh " |^ssh ")) {
              break
            }
            pid = child[pid]
          }

          print pid":"user[pid]":"command[pid]
        }
      '
      ;;
    *)
      ps -t "/dev/$pane_tty" -o user=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -o pid= -o ppid= -o command= | awk -v pane_pid="$pane_pid" -v ssh="$(command -v ssh)" '
        ((/ssh/ && !/-W/ && !/tsh proxy ssh/ && !/sss_ssh_knownhostsproxy/) || !/ssh/) && !/(^|[[:space:]\/])tee([[:space:]]|$)/ {
          user[$2] = $1; if (!child[$3]) child[$3] = $2; pid=$2; $1 = $2 = $3 = ""; command[pid] = substr($0,4)
        }
        END {
          pid = pane_pid
          while (child[pid]) {
            if (match(command[pid], "^" ssh " |^ssh ")) {
              break
            }
            pid = child[pid]
          }

          print pid":"user[pid]":"command[pid]
        }
      '
      ;;
  esac
}

_ssh_or_mosh_args() {
  case "$1" in
    *ssh*)
      args=$(printf '%s' "$1" | sed -E 's/.*\bssh[[:space:]]+//')
      ;;
    *mosh-client*)
      args=$(printf '%s' "$1" | sed -E 's/.*mosh-client -# (.*)\|.*$/\1/; s/-[^ ]*//g')
      ;;
  esac

 printf '%s' "$args"
}

_ssh() {
  username=$1; shift
  if [ "$username" != "$USER" ]; then
    sudo -nku "$username" ssh "$@" 2>/dev/null || command ssh -l "$username" "$@"
  else
    command ssh "$@"
  fi
}

_username() {
  pane_pid=${1:-$(tmux display -p '#{pane_pid}')}
  pane_tty=${2:-$(tmux display -p '#{b:pane_tty}')}
  ssh_only=$3

  pane_info=$(_pane_info "$pane_pid" "$pane_tty")
  command=${pane_info#*:}
  command_username=${command%%:*}
  command=${command#*:}

  ssh_or_mosh_args=$(_ssh_or_mosh_args "$command")
  if [ -n "$ssh_or_mosh_args" ]; then
    # shellcheck disable=SC2086
    username=$(_ssh "$command_username" -G $ssh_or_mosh_args 2>/dev/null | awk '/^user / { print $2; exit }')
    # shellcheck disable=SC2086
    [ -z "$username" ] && username=$(_ssh "$command_username" -T -o BatchMode=yes -o ControlPath=none -o ProxyCommand="sh -c 'echo %%username%% %r >&2'" $ssh_or_mosh_args 2>&1 | awk '/^%username% / { print $2; exit }')
    # shellcheck disable=SC2086
    [ -z "$username" ] && username=$(_ssh "$command_username" -v -T -o BatchMode=yes -o ControlPath=none -o ProxyCommand=false -o IdentityFile='%%username%%/%r' $ssh_or_mosh_args 2>&1 | awk '/%username%/ { print substr($4,12); exit }')
  else
    if ! _is_true "$ssh_only"; then
      username="$command_username"
    fi
  fi

  printf '%s\n' "$username"
}

_hostname() {
  pane_pid=${1:-$(tmux display -p '#{pane_pid}')}
  pane_tty=${2:-$(tmux display -p '#{b:pane_tty}')}
  ssh_only=$3
  full=$4
  h_or_H=$5

  pane_info=$(_pane_info "$pane_pid" "$pane_tty")
  command=${pane_info#*:}
  command_username=${command%%:*}
  command=${command#*:}

  ssh_or_mosh_args=$(_ssh_or_mosh_args "$command")
  if [ -n "$ssh_or_mosh_args" ]; then
    # shellcheck disable=SC2086
    hostname=$(_ssh "$command_username" -G $ssh_or_mosh_args 2>/dev/null | awk '/^hostname / { print $2; exit }')
    # shellcheck disable=SC2086
    [ -z "$hostname" ] && hostname=$(_ssh "$command_username" -T -o BatchMode=yes -o ControlPath=none -o ProxyCommand="sh -c 'echo %%hostname%% %h >&2'" $ssh_or_mosh_args 2>&1 | awk '/^%hostname% / { print $2; exit }')

    if ! _is_true "$full"; then
      case "$hostname" in
          *[A-Za-z-].*)
              hostname=${hostname%%.*}
              ;;
          127.0.0.1)
              hostname="localhost"
              ;;
      esac
    fi
  else
    if ! _is_true "$ssh_only"; then
      hostname="$h_or_H"
    fi
  fi

  printf '%s\n' "$hostname"
}

_fpp() {
  tmux capture-pane -J -S - -E - -b "fpp-$1" -t "$1"
  tmux display-popup -E -d '#{pane_current_path}' -w 80% -h 80% "'$TMUX_PROGRAM' ${TMUX_SOCKET:+-S \"$TMUX_SOCKET\"} show-buffer -b 'fpp-$1' | fpp; '$TMUX_PROGRAM' ${TMUX_SOCKET:+-S \"$TMUX_SOCKET\"} delete-buffer -b 'fpp-$1'"
}

"$@"
