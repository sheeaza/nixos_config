#!/bin/sh

# exit the script if any statement returns a non-true return value
set -e

unset SHELL

unset GREP_OPTIONS
export LC_NUMERIC=C
# shellcheck disable=SC3041
[ -n "${BASH_VERSION:-}" ] && set +H 2>/dev/null || true

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

_pane_info() {
  pane_pid="$1"
  ps -o user=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,pid,ppid,args | awk -v pane_pid="$pane_pid" -v ssh="$(command -v ssh)" '
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
}

_ssh_args() {
  case "$1" in
    *ssh*)
      printf '%s' "$1" | sed -E 's/.*\bssh[[:space:]]+//'
      ;;
  esac
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
  ssh_only=$2

  pane_info=$(_pane_info "$pane_pid")
  command=${pane_info#*:}
  command_username=${command%%:*}
  command=${command#*:}

  ssh_args=$(_ssh_args "$command")
  if [ -n "$ssh_args" ]; then
    # shellcheck disable=SC2086
    username=$(_ssh "$command_username" -G $ssh_args 2>/dev/null | awk '/^user / { print $2; exit }')
  else
    if ! _is_true "$ssh_only"; then
      username="$command_username"
    fi
  fi

  printf '%s\n' "$username"
}

_hostname() {
  pane_pid=${1:-$(tmux display -p '#{pane_pid}')}
  ssh_only=$2
  full=$3
  h_or_H=$4

  pane_info=$(_pane_info "$pane_pid")
  command=${pane_info#*:}
  command_username=${command%%:*}
  command=${command#*:}

  ssh_args=$(_ssh_args "$command")
  if [ -n "$ssh_args" ]; then
    # shellcheck disable=SC2086
    hostname=$(_ssh "$command_username" -G $ssh_args 2>/dev/null | awk '/^hostname / { print $2; exit }')

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

"$@"
