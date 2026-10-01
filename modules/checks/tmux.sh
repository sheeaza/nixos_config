#!/usr/bin/env bash
# Regression tests for the wrapped tmux (packages.mytmux).
#
# This config is a vendored, de-dynamicised oh-my-tmux: the upstream runtime
# sed/awk/perl engine that recomputed styles, bindings and theme strings on every
# config load was replaced by frozen literal output. That trade buys startup time
# but gives up upstream's safety net -- a typo in a baked string no longer fails
# loudly, it just renders wrong. These tests restore the net by starting a real
# server and reading back what it actually resolved.
#
# Covered history:
#   8a15e75, 0d23d07  the perl-removal rewrite
#   7e8e2b5           _pane_info walked the wrong process tree (no -t <tty>)
#   701e53f           _username_marked folds two ps pipelines into one
#   be07c24/c0f4b8e   theme and binding bake-outs
#
# Environment supplied by checks.nix:
#   LIB            path to lib.sh
#   TMUX_BIN       the wrapped tmux binary
#   TMUX_CLOSURE   closureInfo store-paths manifest for mytmux
set -u

# shellcheck source=lib.sh
. "$LIB"

export HOME=$TMPDIR
mkdir -p "$HOME"
SOCK=$TMPDIR/tmux.sock

# Pin the client geometry: status-left/right are truncated to the client width,
# so a narrow default would clip the very segments under test.
t() { "$TMUX_BIN" -S "$SOCK" "$@"; }

section 'server starts cleanly with the baked config'
# Any load error in a baked literal surfaces here and nowhere else.
start_err=$(t new-session -d -s probe -x 200 -y 24 'sleep 120' 2>&1 >/dev/null)
assert_eq 'new-session produces no stderr' "" "$start_err"
if ! t has-session -t probe 2>/dev/null; then
    bad 'server is running'
    finish check-tmux
fi
ok 'server is running'
# Status-line jobs are async: the first render returns placeholders while the
# #() shells are still in flight.
sleep 2

section 'general options'
assert_eq 'default-terminal is pinned to tmux-256color' "tmux-256color" "$(t show -gv default-terminal)"
assert_eq 'escape-time is lowered'   "10"   "$(t show -sv escape-time)"
assert_eq 'focus-events are enabled' "on"   "$(t show -sv focus-events)"
assert_eq 'history-limit is raised'  "5000" "$(t show -gv history-limit)"
assert_eq 'status-interval is 10'    "10"   "$(t show -gv status-interval)"
assert_eq 'activity is monitored'    "on"   "$(t show -gv monitor-activity)"
assert_eq 'activity is not visual'   "off"  "$(t show -gv visual-activity)"

section 'RGB passthrough is unconditional (vendored _apply_24b)'
# Upstream only added this when the client's TERM was not screen-/tmux-; here it
# is hardcoded on, so assert it survived the bake.
assert_contains 'terminal-features advertises RGB for 256col' \
    "$(t show -sv terminal-features)" "*256col*:RGB"
assert_contains 'terminal-overrides carries the Smulx undercurl cap' \
    "$(t show -sv terminal-overrides)" "Smulx"

section 'display / numbering'
assert_eq 'windows are 1-indexed'       "1"    "$(t show -gv base-index)"
assert_eq 'panes are 1-indexed'         "1"    "$(t show -gv pane-base-index)"
assert_eq 'windows renumber on close'   "on"   "$(t show -gv renumber-windows)"
assert_eq 'status line sits at the top' "top"  "$(t show -gv status-position)"
# The config does `set -gu prefix2` to drop the second prefix.
assert_eq 'prefix2 is unset'            "None" "$(t show -gv prefix2)"

section 'new panes and windows retain cwd (baked _apply_bindings)'
# The most regression-prone bake in the file. Upstream injected
# -c "#{pane_current_path}" by regex at load time; stock tmux omits it entirely,
# so a lost literal silently reverts to opening in $HOME.
prefix_keys=$(t list-keys -T prefix)
assert_contains 'prefix - splits vertically in cwd' \
    "$prefix_keys" 'split-window -v -c "#{pane_current_path}"'
assert_contains 'prefix _ splits horizontally in cwd' \
    "$prefix_keys" 'split-window -h -c "#{pane_current_path}"'
assert_contains 'prefix c opens a new window in cwd' \
    "$prefix_keys" 'new-window -c "#{pane_current_path}"'
# The same injection applied to the stock mouse menus, easy to forget because
# they are only reachable by right-click.
root_keys=$(t list-keys -T root)
assert_contains 'the pane mouse menu splits in cwd' \
    "$root_keys" 'split-window -h -c "#{pane_current_path}"'
assert_contains 'the status mouse menu opens windows in cwd' \
    "$root_keys" 'new-window -c "#{pane_current_path}"'

section 'copy-mode-vi bindings'
vi_keys=$(t list-keys -T copy-mode-vi)
assert_contains 'v begins selection'      "$vi_keys" 'v                 send-keys -X begin-selection'
assert_contains 'C-v toggles rectangle'   "$vi_keys" 'C-v               send-keys -X rectangle-toggle'
assert_contains 'y copies and cancels'    "$vi_keys" 'y                 send-keys -X copy-selection-and-cancel'
assert_contains 'Escape cancels'          "$vi_keys" 'Escape            send-keys -X cancel'
assert_contains 'H goes to start of line' "$vi_keys" 'H                 send-keys -X start-of-line'
assert_contains 'L goes to end of line'   "$vi_keys" 'L                 send-keys -X end-of-line'

section 'TMUX_SOCKET is exported for tmux.sh'
# tmux.sh exits 255 unless it can find the socket, which would blank every #()
# segment in the status line.
assert_contains 'TMUX_SOCKET is set in the global environment' \
    "$(t show-environment -g TMUX_SOCKET)" "TMUX_SOCKET=$SOCK"

section 'status line renders'
left=$(t display -p '#{T:status-left}')
right=$(t display -p '#{T:status-right}')
assert_contains 'status-left shows the session name'  "$left"  "probe"
assert_contains 'status-left keeps its session glyph' "$left"  "❐"
# Styles are baked literals; a mangled one silently drops the colour.
assert_contains 'status-left keeps its baked yellow style' "$left"  "bg=#ffff00"
assert_contains 'status-right shows the host segment style' "$right" "bg=#e4e4e4"
# A format typo surfaces as a literal #{...} left in the rendered output.
assert_not_contains 'status-left has no unresolved format'  "$left"  '#{'
assert_not_contains 'status-right has no unresolved format' "$right" '#{'

section 'tmux.sh status helpers (7e8e2b5, 701e53f)'
# Locate tmux.sh the way the status line does -- through the wrapper's baked -f
# flag -- so this tracks the real artifact instead of a guess.
conf=$(sed -n 's/.*-f \([^ ]*\.tmux\.conf\).*/\1/p' "$(readlink -f "$TMUX_BIN")" | head -1)
require "could not find the baked -f config in $TMUX_BIN" "$conf"
sh=$(dirname "$conf")/tmux.sh
assert_file_exists 'tmux.sh ships beside the config' "$sh"
assert_executable  'tmux.sh is executable'           "$sh"

pane_pid=$(t display -p '#{pane_pid}')
pane_tty=$(t display -p '#{b:pane_tty}')
export TMUX="$SOCK,1,0" TMUX_SOCKET="$SOCK"

# 7e8e2b5 gave _pane_info `ps -t <tty>`. Before that it scanned every process on
# the host and took whichever pid matched first, so this must resolve the pane's
# real owner -- not empty, and not a crash.
assert_eq "_username_marked resolves the pane owner ($(id -un))" \
    "$(id -un)" "$("$sh" _username_marked "$pane_pid" "$pane_tty" false)"

# The non-ssh branch echoes back tmux's own #h.
assert_eq '_hostname falls back to #h outside ssh' \
    "probehost" "$("$sh" _hostname "$pane_pid" "$pane_tty" false false probehost)"

# 701e53f folded the root "!" marker into _username_marked. The sandbox never
# runs as root, so shim ps to drive that branch directly.
mkdir -p "$TMPDIR/shim"
cat > "$TMPDIR/shim/ps" <<'PS_SHIM'
#!/bin/sh
echo "root                            4242  4241 -bash"
PS_SHIM
chmod +x "$TMPDIR/shim/ps"
assert_eq 'root gets a bold blinking ! marker' \
    'root#[bold,blink]!#[default]' \
    "$(PATH=$TMPDIR/shim:$PATH "$sh" _username_marked 4242 pts/9 false)"

section 'closure stays slim (8a15e75, 0d23d07)'
# The whole point of the de-dynamicisation was dropping the perl runtime.
assert_closure_lacks 'perl is absent from the tmux closure' \
    "$TMUX_CLOSURE/store-paths" 'perl-[0-9][^/]*'
# tmux is built with withSystemd = false.
assert_closure_lacks 'systemd is absent from the tmux closure' \
    "$TMUX_CLOSURE/store-paths" 'systemd-[0-9][^/]*'

t kill-server 2>/dev/null || true
finish check-tmux
