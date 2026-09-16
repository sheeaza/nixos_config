#!/bin/sh
# Phase 1 of removing the `perl` dependency from ohmytmux's .tmux.conf: rewrites
# the ~25 "safe" perl call sites (process-name lookup, version parsing, unicode
# decode, path prettifying, timestamps, ssh/mosh arg parsing, uptime status
# tags, dynamic status-bar function expansion, TPM plugin discovery/patching,
# #!important line handling, the sed/awk/perl availability check) to plain
# sh/awk/bash equivalents.
#
# perl is deliberately LEFT IN PLACE for two clusters that are out of scope for
# this phase (real regression risk, not attempted here):
#   - the tmux-keybinding-rewriting metaprogramming block (new-window/
#     split-window/copy-pipe/command-prompt wrapping)
#   - _blank() (Unicode combining-mark stripping + East-Asian width expansion,
#     hot status-bar path)
#
# Every edit below is addressed by searching for a literal anchor string (the
# exact upstream text at that site) rather than a hardcoded line number, so:
#   (a) it is immune to line-number drift caused by earlier edits in this same
#       script shifting the file's line count, and
#   (b) if a future flake.lock bump changes this file upstream, the anchor
#       lookup fails loudly (site not found) instead of silently editing the
#       wrong line.
set -e

f="$1"
[ -n "$f" ] || { echo "rewrite-perl.sh: usage: rewrite-perl.sh <file>" >&2; exit 1; }

# line_of <anchor>: prints the line number of the first line containing the
# literal (non-regex) anchor text, or fails the build loudly if not found.
line_of() {
  n=$(grep -nF "$1" "$f" | head -1 | cut -d: -f1)
  [ -n "$n" ] || { echo "rewrite-perl.sh: expected text not found (upstream ohmytmux may have changed): $1" >&2; exit 1; }
  echo "$n"
}

# replace_line <anchor>: replaces the (first) line containing the literal
# anchor text with stdin (may itself be multi-line).
replace_line() {
  n=$(line_of "$1")
  tmp=$(mktemp)
  cat > "$tmp"
  sed -i -e "${n}r $tmp" -e "${n}d" "$f"
  rm -f "$tmp"
}

# replace_range <anchor> <span>: replaces the <span>-line block starting at
# the (first) line containing the literal anchor text with stdin. <span> is
# the block's line count in the pinned upstream source (a fixed, contiguous
# span relative to its own start line, so it does not depend on any earlier
# edit's line-count drift).
replace_range() {
  start=$(line_of "$1")
  end=$((start + $2 - 1))
  tmp=$(mktemp)
  cat > "$tmp"
  sed -i -e "${start}r $tmp" -e "${start},${end}d" "$f"
  rm -f "$tmp"
}

# --- TMUX_PROGRAM lsof/perl detection (top-level run directive) ---
# lsof is absent from this image's package closure, so `command -v lsof` always
# fails, $LSOF expands empty, and this branch is dead code today regardless of
# perl. `false` preserves that same always-fails behavior and lets the existing
# `|| readlink "/proc/#{pid}/exe"` fallback (correct on Linux) take over.
n=$(line_of 'command -v lsof); \$LSOF -b -w -a -d txt -p #{pid} -Fn 2>/dev/null | perl -n -e')
sed -i "${n}s/\\\\\$LSOF.*|| readlink/false || readlink/" "$f"

# --- same lsof/perl detection, sourced-script fallback copy ---
n=$(line_of 'TMUX_PROGRAM=$(lsof -b -w -a -d txt -p "$TMUX_PID" -Fn 2>/dev/null | perl -n -e')
sed -i "${n}s/lsof -b -w.*|| readlink/false || readlink/" "$f"

# --- _tmux_version(): "3.4a" -> integer version code ---
replace_line '__tmux_version:=$(tmux -V | perl -n -e' <<'EOF'
#   : "${__tmux_version:=$(tmux -V | awk '{ s=$0; sub(/^[^0-9]+/,"",s); sub(/[-+].*/,"",s); match(s,/^[0-9.]+/); n=substr(s,RSTART,RLENGTH); r=substr(s,RSTART+RLENGTH,1); if (r !~ /[a-z]/) r=""; printf "%d\n", n*1000 + (r=="" ? 0 : index("abcdefghijklmnopqrstuvwxyz", r)) }')}"
EOF

# --- _decode_unicode_escapes(): \uXXXX / \UXXXXXXXX -> UTF-8 ---
replace_line "printf '%s' \"\$*\" | perl -CS -pe" <<'EOF'
#       LC_ALL=C.UTF-8 @bash@ -c 'printf "%b" "$1"' -- "$*"
EOF

# --- _pretty_path(): abbreviate long paths with "..." (original site spans 5
# lines: the `perl -s -p -E '` opener, 3 substitution-pattern continuation
# lines, and the closing `' -- -HOME=... -max_length=...`, PLUS that 5-line
# span's last line is the function's own closing `}` -- must be preserved) ---
replace_range "IFS=' '; cd \"\$*\" && pwd || printf '%s' \"\$*\";  } | perl -s -p -E" 5 <<'EOF'
#   { IFS=' '; cd "$*" && pwd || printf '%s' "$*";  } | awk -v home="$HOME" -v max="$max_length" '{ line = $0; if (index(line, home) == 1) line = "~" substr(line, length(home)+1); if (length(line) <= max) { print line; next } n = split(line, parts, "/"); if (n >= 4) { print parts[1] "/" parts[2] "/.../" parts[n]; next } if (n >= 3) { print parts[1] "/.../" parts[n]; next } print line }'
# }
EOF

# --- _timestamp(): drop the perl-based sub-second logger, keep the existing
# non-perl Linux/BSD fallback (already present in the file) unconditionally ---
replace_range 'if perl -MTime::HiRes -e1; then' 24 <<'EOF'
#     case "$(_uname_s)" in
#       Darwin|DragonFly|*BSD)
#         __timestamp() {
#           while IFS= read -r line; do
#             printf '[%s]\t%s\n' "$(date +"%Y-%m-%d %H:%M:%S.000")" "$line"
#           done
#         }
#         ;;
#       *)
#         __timestamp() {
#           while IFS= read -r line; do
#             printf '[%s]\t%s\n' "$(date +"%Y-%m-%d %H:%M:%S.%3N")" "$line"
#           done
#         }
#         ;;
#     esac
EOF

# --- _ssh_or_mosh_args(): extract the ssh/mosh-client argument string ---
replace_line "args=\$(printf '%s' \"\$1\" | perl -n -e 'print if s/.*?(?:^|[\\s\\/])ssh" <<'EOF'
#       args=$(printf '%s' "$1" | sed -E 's/.*\bssh[[:space:]]+//')
EOF

replace_line "args=\$(printf '%s' \"\$1\" | perl -p -e 's/.*mosh-client" <<'EOF'
#       args=$(printf '%s' "$1" | sed -E 's/.*mosh-client -# (.*)\|.*$/\1/; s/-[^ ]*//g')
EOF

# --- uptime status-tag renaming ---
replace_range "status_left=\$(printf '%s\\n' \"\$status_left\" | perl -p -e" 7 <<'EOF'
#       status_left=$(printf '%s\n' "$status_left" | sed -E '
#         s/#\{(\?)?uptime_y\b/#{\1@uptime_y/g
#         s/#\{(\?)?uptime_d\b/#{\1@uptime_d/g
#         /@uptime_y\b/ s/@uptime_d\b/@uptime_dy/g
#         s/#\{(\?)?uptime_h\b/#{\1@uptime_h/g
#         s/#\{(\?)?uptime_m\b/#{\1@uptime_m/g
#         s/#\{(\?)?uptime_s\b/#{\1@uptime_s/g')
EOF

replace_range "status_right=\$(printf '%s\\n' \"\$status_right\" | perl -p -e" 7 <<'EOF'
#       status_right=$(printf '%s\n' "$status_right" | sed -E '
#         s/#\{(\?)?uptime_y\b/#{\1@uptime_y/g
#         s/#\{(\?)?uptime_d\b/#{\1@uptime_d/g
#         /@uptime_y\b/ s/@uptime_d\b/@uptime_dy/g
#         s/#\{(\?)?uptime_h\b/#{\1@uptime_h/g
#         s/#\{(\?)?uptime_m\b/#{\1@uptime_m/g
#         s/#\{(\?)?uptime_s\b/#{\1@uptime_s/g')
EOF

# --- dynamic "#{funcname args}" status-bar expansion: perl built a
# substitution *program* at runtime from user-defined `# name() {` functions
# in TMUX_CONF_LOCAL; replicate with an awk-generated sed script. ---
replace_range 'replacements=$(perl -n -e' 3 <<'EOF'
#     replacements=$(awk -v conf="$TMUX_CONF_LOCAL" '
#       match($0, /^#[[:space:]]*[a-zA-Z][a-zA-Z0-9_]*\(\)[[:space:]]*\{/) {
#         name=$0
#         sub(/^#[[:space:]]*/, "", name)
#         sub(/\(\).*/, "", name)
#         printf "s~#\\{%s((\\s+([^{}]+|#\\{[^{}]*\\}))*)\\}~#(cut -c3- '"'"'%s'"'"' | sh -s %s\\1)~g\n", name, conf, name
#       }
#     ' "$TMUX_CONF_LOCAL")
#     status_left=$(printf '%s\n' "$status_left" | { [ -n "$replacements" ] && sed -E "$replacements" || cat; })
#     status_right=$(printf '%s\n' "$status_right" | { [ -n "$replacements" ] && sed -E "$replacements" || cat; })
EOF

# --- TPM plugin discovery ---
replace_line 'source -nvq "$current_file" | perl -s -n -E' <<'EOF'
#           TMUX_SOCKET="$probe_socket" tmux -f /dev/null source -nvq "$current_file" | awk -v cf="$current_file" '{ if (index($0, cf ":") == 1) { rest = substr($0, length(cf) + 2); sub(/^[0-9]+:[ \t]*/, "", rest); if (rest ~ /^(set-option[ \t]+-g[ \t]+@plugin[ \t]+|source-file)/) print rest } }'
EOF

replace_line "if plugin=\$(printf '%s\\n' \"\$line\" | perl -s -n -E 'print if s/^set" <<'EOF'
#           if plugin=$(printf '%s\n' "$line" | sed -n -E 's/^set(-option)?[[:space:]]+-g[[:space:]]+@plugin[[:space:]]+//p') && [ -n "$plugin" ]; then
EOF

replace_line "elif next_files=\$(printf '%s\\n' \"\$line\" | perl -s -n -E 's/(?<!\\@)current_file/" <<'EOF'
#           elif next_files=$(printf '%s\n' "$line" | awk '{ s = $0; gsub(/@current_file/, "\001", s); gsub(/current_file/, "@current_file", s); gsub(/\001/, "@current_file", s); if (s ~ /^source(-file)?([ \t]+-[a-zA-Z]+)*[ \t]+-[a-zA-Z]*n[a-zA-Z]*/) { exit 1 } if (s ~ /^source(-file)?([ \t]+-[qFv]+)*[ \t]*/) { sub(/^source(-file)?([ \t]+-[qFv]+)*[ \t]*/, "", s); print s } else { exit 1 } }') && [ -n "$next_files" ]; then
EOF

# --- TPM script patches ---
# install_plugins.sh: keep the idempotent "add --depth 1 to git clone" guard;
# drop the second perl substitution (parallelizing installs with `wait`) since
# it's a pure performance optimization, not correctness, and its lookahead-based
# multi-line rewrite of a third-party (git-cloned-at-runtime) script is real
# regression risk for no functional loss if skipped -- plugins still install
# correctly, just sequentially.
replace_range 'perl -0777 -p -i -e' 2 <<'EOF'
#           grep -q 'git clone --depth 1' "$TMUX_PLUGIN_MANAGER_PATH/tpm/scripts/install_plugins.sh" || sed -i 's/git clone /git clone --depth 1 /' "$TMUX_PLUGIN_MANAGER_PATH/tpm/scripts/install_plugins.sh"
EOF

replace_line 'git submodule update --init --recursive(?!' <<'EOF'
#           grep -q 'git submodule update --init --recursive --depth 1' "$TMUX_PLUGIN_MANAGER_PATH/tpm/scripts/update_plugin.sh" || sed -i 's/git submodule update --init --recursive/git submodule update --init --recursive --depth 1/' "$TMUX_PLUGIN_MANAGER_PATH/tpm/scripts/update_plugin.sh"
EOF

replace_line '\$tmux_file\s+>/dev/null\s+2>\&1' <<'EOF'
#           sed -i -E 's/\$tmux_file[[:space:]]+>\/dev\/null[[:space:]]+2>&1/& || { tmux display "Plugin \$(basename \${plugin_path}) failed" \&\& false; }/' "$TMUX_PLUGIN_MANAGER_PATH/tpm/scripts/source_plugins.sh"
EOF

# --- _apply_important(): #!important line filtering + retry-on-bad-line ---
replace_line "if perl -n -e 'print if /^\\s*(?:set|bind|unbind)" <<'EOF'
#   if grep -E '^[[:space:]]*(set|bind|unbind).+#!important[[:space:]]*$' "$TMUX_CONF_LOCAL" 2>/dev/null > "$cfg.local"; then
EOF

replace_line 'perl -n -i -e "if ($. != $line) { print }" "$cfg.local"' <<'EOF'
#         sed -i "${line}d" "$cfg.local"
EOF

# --- _apply_bindings() source-file retry loop: same line-delete-by-number
# pattern as _apply_important above, just against a different temp file. ---
replace_line 'perl -n -i -e "if ($. != $line) { print }" "$cfg.in"' <<'EOF'
#       sed -i "${line}d" "$cfg.in"
EOF

# --- _apply_bindings(): tmux < 3.0 list-keys truncation workaround. Fixed
# string, end-of-line-anchored -- no lookahead/lookbehind/backreferences, so
# it translates directly to a sed -E substitution (already used elsewhere in
# this file and confirmed supported by busybox sed). ---
replace_line "s/'#\\{\\?window_zoomed_flag,Unzoom,Zoom\\}' 'z' \\{resize-pane -\$/" <<'EOF'
#   sed -i -E "s/'#\{\?window_zoomed_flag,Unzoom,Zoom\}' 'z' \{resize-pane -\$/'#{?window_zoomed_flag,Unzoom,Zoom}' 'z' {resize-pane -Z}\"/" "$cfg"
EOF

# --- _apply_bindings(): new-window idempotency cleanup. Runs on every
# reload (guarded only by `_is_disabled`, not `_is_true` -- it must reset
# state left over from ANY previously-active new-window feature, not just
# retain-path, so that the wrap/inject statements below it can cleanly
# reapply from a blank slate). 3 perl statements, no lookaround: (1) inside
# an existing run-shell-wrapped `_new_window` invocation, strip a baked-in
# `-c "#{pane_current_path}"` flag but keep the wrap (handles reconnect_ssh
# staying on while retain-path turns off); (2) unconditionally unwrap any
# (now flag-less) run-shell-wrapped `_new_window` invocation back to a bare
# `new-window`, preserving any other trailing flags -- deliberately matches
# literal `_new_window` only (`\s+` immediately after, not `_new_window_ssh`)
# so the ssh-detection wrap from the next block survives untouched; (3)
# strip a `-c "#{pane_current_path}"` flag from an already-bare (non
# run-shell-wrapped) new-window -- tmux's list-keys re-serializes this
# simple flag argument to double quotes regardless of what quote character
# the inject statement below originally wrote, the form produced by the unconditional
# inject statement below when nothing needed wrapping. Each capture group
# is bounded to a delimiter set that can't appear inside it, rather than
# perl's unrestricted `.+`/lazy quantifiers (POSIX ERE has no non-greedy
# quantifier): closing `'`/`"` for the trailing flag captures, and -- for the
# double-quote-outer variants of statements 1-2 -- the baked-in path capture
# itself is bounded to `[^|]+` (the pipe character can't appear in a nix
# store path). Without that path bound, `.+` greedily matches across the
# double quotes that structurally surround the path (`"cut -c3- \"...\" |"`),
# and on a line with multiple run-shell occurrences (e.g. a display-menu
# binding with both a "New After" and a "New At End" entry) it backtracks
# from the rightmost match, swallowing everything between the first and last
# occurrence into one capture group and corrupting the line. Empirically
# confirmed via the real live multi-item display-menu binding (see the
# retain-path "full apply" block below), which is why the double-quote path
# capture is bounded here but the display-menu case doesn't need its own
# explicit bound -- there each menu item is separated by its own enclosing
# `}`, which already blocks `.+` from crossing into the next item. Statements
# 1 and 2 each run twice, once assuming single-quote-outer (the literal form
# the wrap/inject sed replacement text below writes) and once assuming
# double-quote-outer with backslash-escaped inner quotes -- empirically,
# `$cfg` (captured via `tmux list-keys`, which re-serializes stored argv
# using tmux's own quoting rules) is ALWAYS double-quote-outer for this
# wrapped+flagged combination by the time this cleanup runs, but the
# single-quote-outer variant is kept as a harmless no-op fallback (it never
# matches in practice, so its unbounded `.+` carries no swallowing risk) in
# case any upstream/tmux-version combination ever produces single-quote-outer
# output here. ---
replace_range 'if ! _is_disabled "$tmux_conf_new_window_retain_current_path"; then' 9 <<'EOF'
#   if ! _is_disabled "$tmux_conf_new_window_retain_current_path"; then
#     sed -i -E "s/\brun-shell\b 'cut -c3- (.+) \| sh -s _new_window #\{pane_pid\} #\{b:pane_tty\}([^']*) -c \"#\{pane_current_path\}\"([^']*)'/run-shell 'cut -c3- \1 | sh -s _new_window #\{pane_pid\} #\{b:pane_tty\}\2\3'/g" "$cfg"
#     sed -i -E 's/\brun-shell\b "cut -c3- ([^|]+) \| sh -s _new_window #\{pane_pid\} #\{b:pane_tty\}([^"]*) -c \\"#\{pane_current_path\}\\"([^"]*)"/run-shell "cut -c3- \1 | sh -s _new_window #\{pane_pid\} #\{b:pane_tty\}\2\3"/g' "$cfg"
#     sed -i -E "s/\brun-shell\b 'cut -c3- .+ \| sh -s _new_window #\{pane_pid\} #\{b:pane_tty\}([^']*)'/new-window\1/g" "$cfg"
#     sed -i -E 's/\brun-shell\b "cut -c3- [^|]+ \| sh -s _new_window #\{pane_pid\} #\{b:pane_tty\}([^"]*)"/new-window\1/g' "$cfg"
#     sed -i -E "s/\bnew-window\b([^;}]*) -c \"#\{pane_current_path\}\"/new-window\1/g" "$cfg"
#   fi
EOF

# --- _apply_bindings(): split-window idempotency cleanup. Mirror of the
# new-window idempotency cleanup above, same rationale (runs on every
# reload, guarded only by `_is_disabled`; 3 perl statements -> 5 sed
# statements, bounded capture groups instead of perl's lazy `.+?`, quote-
# variant duplication instead of perl's single `("|')` alternation capture
# since POSIX ERE backreferences need the same literal quote char on both
# sides and duplicating per-quote-style is simpler than emulating perl's
# alternation-capture-then-backreference here). `_split_window` (not
# `_split_window_ssh`) as the literal anchor, same as new-window's
# `_new_window`, so the ssh-detection wrap survives untouched. Double-quote-
# outer is the primary case (confirmed empirically against a real `tmux
# list-keys`-captured $cfg, same as new-window's); single-quote-outer is a
# harmless no-op fallback mirroring the wrap sed's own quoting convention. ---
replace_range 'tmux_conf_new_pane_retain_current_path:=true' 10 <<'EOF'
#   : "${tmux_conf_new_pane_retain_current_path:=true}"
#   if ! _is_disabled "$tmux_conf_new_pane_retain_current_path"; then
#     sed -i -E "s/\brun-shell\b 'cut -c3- (.+) \| sh -s _split_window #\{pane_pid\} #\{b:pane_tty\}([^']*) -c \"#\{pane_current_path\}\"([^']*)'/run-shell 'cut -c3- \1 | sh -s _split_window #\{pane_pid\} #\{b:pane_tty\}\2\3'/g" "$cfg"
#     sed -i -E 's/\brun-shell\b "cut -c3- ([^|]+) \| sh -s _split_window #\{pane_pid\} #\{b:pane_tty\}([^"]*) -c \\"#\{pane_current_path\}\\"([^"]*)"/run-shell "cut -c3- \1 | sh -s _split_window #\{pane_pid\} #\{b:pane_tty\}\2\3"/g' "$cfg"
#     sed -i -E "s/\brun-shell\b 'cut -c3- .+ \| sh -s _split_window #\{pane_pid\} #\{b:pane_tty\}([^']*)'/split-window\1/g" "$cfg"
#     sed -i -E 's/\brun-shell\b "cut -c3- [^|]+ \| sh -s _split_window #\{pane_pid\} #\{b:pane_tty\}([^"]*)"/split-window\1/g' "$cfg"
#     sed -i -E "s/\bsplit-window\b([^;}]*) -c \"#\{pane_current_path\}\"/split-window\1/g" "$cfg"
#   fi
EOF

# --- new-window/split-window SSH-detection wrap: distinct from (and runs
# BEFORE) the unconditional SSH-reconnect wrap below. This one only fires
# when a binding's own STATIC TEXT literally contains the bare word `ssh`
# (e.g. a user's custom `bind X split-window ssh myhost`) and reroutes it to
# the _new_window_ssh/_split_window_ssh helper, same #{pane_pid}/#{b:pane_tty}
# convention as the other wraps. Any trailing ssh args (hostname etc.) are
# left dangling after the closing quote, matching upstream perl exactly --
# the helper reconnects to whatever ssh session is running in the pane
# rather than using a statically-specified host.
#
# Dropped vs. upstream: the negative lookahead `(?!\bssh\b)` guarding
# -c/-e/-l/-n/-t/-F flag arguments (busybox sed has no lookaround, and this
# never fires in practice -- no binding anywhere in this repo or ohmytmux's
# own defaults ever uses a flag argument that's literally the bare word
# "ssh"), and the redundant trailing `if /.../ ` line-gate (a no-op: the
# substitution's own pattern already requires the same match to fire at all).
#
# Delimiter is `,` (matching perl's own choice), NOT `/`: the replacement
# bakes in a literal `\"$TMUX_CONF\"` path, and busybox sed fails with "bad
# option in substitution expression" when `/` is both the delimiter and
# present literally inside the replacement text.
#
# Anchored on the inner sed line (unique per new-window/split-window) rather
# than the `perl -p -i -e "` opener above it, since that opener text recurs
# throughout the file and isn't unique on its own; start/end are computed as
# anchor-1/anchor+1 to capture the full 3-line perl statement (open-quote
# line, regex+if line, closing "$cfg" line).
#
# Verified byte-for-byte identical to actual perl (5.42.3, invoked directly
# from its nix store path inside the build container) against
# bare-ssh-with-trailing-hostname, quoted-string (`"ssh myhost"`, untouched),
# flag-prefixed (-c/-t), bare-ssh-only, and no-ssh forms, for both commands. ---
n=$(line_of 's,\bnew-window\b((?:(?:[ \t]+-[abdfhkIvPSZ])')
start=$((n - 1)); end=$((n + 1))
tmp=$(mktemp); cat > "$tmp" <<'EOF'
#   sed -i -E "s,\bnew-window\b(([[:space:]]+-[abdfhkIvPSZ]|[[:space:]]+-[celntF][[:space:]]+[^[:space:]]+)*)[[:space:]]+ssh\b([[:space:]]+-[abdfhkIvPSZ]|[[:space:]]+-[celntF][[:space:]]+[^[:space:]]+)*,run-shell 'cut -c3- \"$TMUX_CONF\" | sh -s _new_window_ssh #\{pane_pid\} #\{b:pane_tty\}\1',g" "$cfg"
EOF
sed -i -e "${start}r $tmp" -e "${start},${end}d" "$f"
rm -f "$tmp"

n=$(line_of 's,\bsplit-window\b((?:(?:[ \t]+-[abdfhkIvPSZ])')
start=$((n - 1)); end=$((n + 1))
tmp=$(mktemp); cat > "$tmp" <<'EOF'
#   sed -i -E "s,\bsplit-window\b(([[:space:]]+-[abdfhkIvPSZ]|[[:space:]]+-[celntF][[:space:]]+[^[:space:]]+)*)[[:space:]]+ssh\b([[:space:]]+-[abdfhkIvPSZ]|[[:space:]]+-[celntF][[:space:]]+[^[:space:]]+)*,run-shell 'cut -c3- \"$TMUX_CONF\" | sh -s _split_window_ssh #\{pane_pid\} #\{b:pane_tty\}\1',g" "$cfg"
EOF
sed -i -e "${start}r $tmp" -e "${start},${end}d" "$f"
rm -f "$tmp"

# --- new-window/split-window SSH-reconnect wrap: gated behind
# tmux_conf_new_window_reconnect_ssh/tmux_conf_new_pane_reconnect_ssh (both
# `false` by default and in this repo's tmuxlocal, so currently a no-op here).
# Unlike the SSH-detection wrap above, this one is unconditional on binding
# CONTENT: when enabled, it rewires EVERY new-window/split-window binding,
# regardless of what it runs, into the _new_window/_split_window helper --
# which inspects the CURRENT pane's actual running process at runtime and
# reconnects if it's ssh, rather than matching on the binding's static text.
# Plain \bWORD\b anchor + bounded negated-character-class capture group, no
# lookahead/lookbehind/non-greedy quantifiers -- translates directly to sed -E
# (busybox sed confirmed to support \b, capture groups, and \N backreferences
# in the replacement via an empirical container test). ---
replace_line 's,\bnew-window\b([^;}\n\"]*),run-shell' <<'EOF'
#     sed -i -E "s,\bnew-window\b([^;}\"]*),run-shell 'cut -c3- \"$TMUX_CONF\" | sh -s _new_window #\{pane_pid\} #\{b:pane_tty\}\1',g" "$cfg"
EOF

replace_line 's,\bsplit-window\b([^;}\n\"]*),run-shell' <<'EOF'
#     sed -i -E "s,\bsplit-window\b([^;}\"]*),run-shell 'cut -c3- \"$TMUX_CONF\" | sh -s _split_window #\{pane_pid\} #\{b:pane_tty\}\1',g" "$cfg"
EOF

# --- _apply_bindings(): new-window current-path retention, "full apply" --
# 4 perl statements, no lookaround at all (new-window has no analogous
# command-prompt-wrap feature, so unlike the new-session/new-window-prompt
# blocks there's no lookbehind needed to protect a prompt label). (1) inside
# display-menu lines only (perl's trailing `if /\bdisplay-menu\b/` modifier,
# replicated as a sed address-restricted block), brace-wrap a bare
# new-window; (2) unconditionally, append `-c '#{pane_current_path}'` to
# every remaining bare new-window (this also fires on the just-braced
# `{new-window}` from step 1, exactly like the perl original -- both regard
# `new-window` as a bare word regardless of surrounding braces); (3) inside
# display-menu lines only, inject an escaped `-c \"#{pane_current_path}\"`
# into an already run-shell-wrapped (ssh-reconnect) _new_window invocation;
# (4) unconditionally, inject a plain `-c "#{pane_current_path}"` into an
# already run-shell-wrapped _new_window invocation elsewhere. Byte-verified
# via od against the pinned source that the display-menu variant (3) truly
# uses one extra backslash-quote pair versus the plain variant (4) -- this
# is tmux's own display-menu `{...}` command text needing one more level of
# quote-escaping, not an arbitrary perl quirk, so both variants are kept
# distinct. Statements 3 and 4 are naturally mutually exclusive despite (4)
# being unconditional: after (3) fires, the injected `#{pane_current_path}`
# contains a `}` that falls inside (4)'s `[^}'\n]*` capture group's required
# span, breaking its match on that transformed line -- same as upstream
# perl, no extra guard needed. Verified in a container (GNU sed on the host
# and busybox sed inside the image, byte-identical output) against a bare
# new-window binding, a display-menu-wrapped new-window item, a plain
# ssh-reconnect run-shell wrap, a display-menu ssh-reconnect run-shell wrap,
# and an ssh-reconnect wrap carrying a trailing flag (`-t :0`) after
# `#{b:pane_tty}` to confirm the injected `-c` flag is placed before any
# pre-existing trailing flags, matching perl's capture-group ordering. ---
replace_range 'if ! _is_disabled "$tmux_conf_new_window_retain_current_path" && _is_true "$tmux_conf_new_window_retain_current_path"; then' 11 <<'EOF'
#   if ! _is_disabled "$tmux_conf_new_window_retain_current_path" && _is_true "$tmux_conf_new_window_retain_current_path"; then
#     sed -i -E "/display-menu/{
#       s/\{new-window\b/{NWPROTECTED/g
#       s/new-window\b([[:space:]]+-)/NWPROTECTED\1/g
#       s/new-window\b([[:space:]]+\})/NWPROTECTED\1/g
#       s/\bnew-window\b/{new-window}/g
#       s/NWPROTECTED/new-window/g
#     }" "$cfg"
#     sed -i -E "s/\bnew-window\b/new-window -c '#{pane_current_path}'/g" "$cfg"
#     sed -i -E "/display-menu/ s/run-shell 'cut -c3- (.+) \| sh -s _new_window(_ssh)? #\{pane_pid\} #\{b:pane_tty\}([^}'\n]*)'/run-shell 'cut -c3- \1 | sh -s _new_window\2 #\{pane_pid\} #\{b:pane_tty\} -c \\\"#\{pane_current_path\}\\\"\3'/g" "$cfg"
#     sed -i -E "s/run-shell 'cut -c3- (.+) \| sh -s _new_window(_ssh)? #\{pane_pid\} #\{b:pane_tty\}([^}'\n]*)'/run-shell 'cut -c3- \1 | sh -s _new_window\2 #\{pane_pid\} #\{b:pane_tty\} -c \"#\{pane_current_path\}\"\3'/g" "$cfg"
#   fi
EOF

# --- _apply_bindings(): split-window current-path retention, "full apply" --
# Mirror of the new-window "full apply" block above -- identical 4-statement
# structure, `split-window`/`_split_window(_ssh)?` substituted for
# `new-window`/`_new_window(_ssh)?` throughout. Placeholder token renamed to
# SWPROTECTED (vs NWPROTECTED) only to avoid any accidental cross-block
# collision; behaviorally identical. See the new-window block's comment for
# the full per-statement rationale (display-menu-restricted brace-wrap of
# bare split-window; unconditional -c append; display-menu-only escaped -c
# injection into an already-wrapped run-shell call; unconditional plain -c
# injection elsewhere -- naturally mutually exclusive post-transformation). ---
replace_range 'if ! _is_disabled "$tmux_conf_new_pane_retain_current_path" && _is_true "$tmux_conf_new_pane_retain_current_path"; then' 11 <<'EOF'
#   if ! _is_disabled "$tmux_conf_new_pane_retain_current_path" && _is_true "$tmux_conf_new_pane_retain_current_path"; then
#     sed -i -E "/display-menu/{
#       s/\{split-window\b/{SWPROTECTED/g
#       s/split-window\b([[:space:]]+-)/SWPROTECTED\1/g
#       s/split-window\b([[:space:]]+\})/SWPROTECTED\1/g
#       s/\bsplit-window\b/{split-window}/g
#       s/SWPROTECTED/split-window/g
#     }" "$cfg"
#     sed -i -E "s/\bsplit-window\b/split-window -c '#{pane_current_path}'/g" "$cfg"
#     sed -i -E "/display-menu/ s/run-shell 'cut -c3- (.+) \| sh -s _split_window(_ssh)? #\{pane_pid\} #\{b:pane_tty\}([^}'\n]*)'/run-shell 'cut -c3- \1 | sh -s _split_window\2 #\{pane_pid\} #\{b:pane_tty\} -c \\\"#\{pane_current_path\}\\\"\3'/g" "$cfg"
#     sed -i -E "s/run-shell 'cut -c3- (.+) \| sh -s _split_window(_ssh)? #\{pane_pid\} #\{b:pane_tty\}([^}'\n]*)'/run-shell 'cut -c3- \1 | sh -s _split_window\2 #\{pane_pid\} #\{b:pane_tty\} -c \"#\{pane_current_path\}\"\3'/g" "$cfg"
#   fi
EOF

# --- _apply_bindings(): copy-to-OS-clipboard wrap. Only the "wrap" branch
# (tmux_conf_copy_to_os_clipboard enabled) is converted here; the two "unwrap"
# branches below it (tmux>=3200 / tmux<3200) are converted separately below.
# $clipboard_command is one of six fixed shell-detected values (xsel/xclip/
# wl-copy/pbcopy/clip.exe/cat>clipboard), pre-escaped upstream for safe dual
# use as pattern-or-replacement text (\/ for embedded slashes, \& so it can't
# be misread as sed's "whole match" token, \. for the one literal dot in
# clip.exe) -- verified empirically against all six values that this
# pre-escaping is directly reusable, unchanged, in a `/`-delimited sed
# pattern/replacement. `(?:selection|pipe)` has no non-capturing form in
# POSIX ERE, so it becomes capture group 1 (unused) and the suffix shifts to
# \2. Perl's negative lookahead `(?!.*?$clipboard_command)` -- "don't
# re-wrap a line that already contains the clipboard command" -- has no ERE
# equivalent, so it becomes a per-line sed address guard `/$clipboard_command/!`,
# which is exactly equivalent since the lookahead's reach is unbounded to the
# end of the line/pattern space (same scope sed's whole-line address test
# covers) and clipboard_command only ever appears (if at all) already
# trailing a prior copy-pipe/copy-selection rewrite on that same line. ---
replace_line 's/(?!.*?$clipboard_command)\bcopy-(?:selection|pipe)' <<'EOF'
#       sed -i -E "/$clipboard_command/! s/\bcopy-(selection|pipe)(-end-of-line-and-cancel|-end-of-line|-line-and-cancel|-line|-and-cancel|-no-clear)?\b/copy-pipe\2 '$clipboard_command'/g" "$cfg"
EOF

# --- _apply_bindings(): copy-pipe unwrap, tmux>=3200 branch. Sibling of the
# wrap block above -- runs when tmux_conf_copy_to_os_clipboard is disabled, to
# strip a previously-appended clipboard command back off a copy-pipe binding.
# Unlike the wrap block's `(?:selection|pipe)`, this pattern's groups map
# directly onto sed's numbered captures (group 1 = suffix, group 2 = the
# optional wrapping quote), so no renumbering is needed: \1/\2 in perl are
# \1/\2 in sed too. The trailing `\2?` is a backreference WITHIN the pattern
# (not just the replacement) requiring the closing quote to match whichever
# one (if any) was captured at the front -- confirmed empirically that GNU
# sed's `-E` mode supports in-pattern backreferences the same as perl here. ---
replace_line 's/\bcopy-pipe(-end-of-line-and-cancel|-end-of-line|-line-and-cancel|-line|-and-cancel|-no-clear)?\b\s+(\"|'"'"')?$clipboard_command\2?/copy-pipe\1/g" "$cfg"' <<'EOF'
#         sed -i -E "s/\bcopy-pipe(-end-of-line-and-cancel|-end-of-line|-line-and-cancel|-line|-and-cancel|-no-clear)?\b[[:space:]]+(\"|')?$clipboard_command\2?/copy-pipe\1/g" "$cfg"
EOF

# --- _apply_bindings(): copy-pipe unwrap, tmux<3200 branch. Identical pattern
# to the tmux>=3200 branch above, except the replacement renames the binding
# to copy-selection<suffix> instead of copy-pipe<suffix> (tmux <3.2 lacks the
# copy-pipe key-table action, so ohmytmux falls back to the older
# copy-selection action name). Same in-pattern backreference reasoning
# applies. ---
replace_line 's/\bcopy-pipe(-end-of-line-and-cancel|-end-of-line|-line-and-cancel|-line|-and-cancel|-no-clear)?\b\s+(\"|'"'"')?$clipboard_command\2?/copy-selection\1/g" "$cfg"' <<'EOF'
#         sed -i -E "s/\bcopy-pipe(-end-of-line-and-cancel|-end-of-line|-line-and-cancel|-line|-and-cancel|-no-clear)?\b[[:space:]]+(\"|')?$clipboard_command\2?/copy-selection\1/g" "$cfg"
EOF

# --- _apply_bindings(): new-session command-prompt wrap -- if-branch (wrap)
# and else-branch (unwrap) converted together, same reasoning as the
# retain-current-path block below (shared perl opener isn't a unique anchor).
# The if-branch has two perl statements: (1) inside display-menu lines only
# (perl's trailing `if /\bdisplay-menu\b/` statement modifier -- replicated
# here as a sed address restriction `/display-menu/{...}`), wrap a bare
# new-session in `{...}` unless already braced or already command-prompt-
# wrapped or already flagged/closing-braced immediately after (lookbehind
# "(?<!{)(?<!command-prompt -p )" + lookahead "(?!\s+(?:-|}))"); (2)
# unconditionally (all lines), wrap any remaining bare new-session into the
# command-prompt-prompted form, protected by lookbehind
# "(?<!\bcommand-prompt -p )" (don't double-wrap the label) and lookahead
# "(?! -s)" (don't re-wrap the already-wrapped inner command). Both
# lookarounds replicated via the same protect-with-placeholder/restore trick
# used elsewhere in this file (busybox sed's ERE has no lookaround). Verified
# in a container against tmux's own built-in default bindings (`C-c` bound to
# plain `new-session`, and the root-table mouse display-menu's braced
# `{ new-session }` "New Session" item) for: initial wrap, idempotent
# re-application (no double-wrap), and the else-branch's unwrap restoring the
# original text exactly. The else-branch's perl is a single literal-structure
# regex (no lookaround) so it translates directly to one sed -E substitution. ---
replace_range 'if ! _is_disabled "$tmux_conf_new_session_prompt" && _is_true "$tmux_conf_new_session_prompt"; then' 9 <<'EOF'
#   if ! _is_disabled "$tmux_conf_new_session_prompt" && _is_true "$tmux_conf_new_session_prompt"; then
#     sed -i -E '/display-menu/{
#       s/\{new-session\b/{NSPROTECTED/g
#       s/command-prompt -p new-session\b/command-prompt -p NSPROTECTED/g
#       s/new-session\b([[:space:]]+-)/NSPROTECTED\1/g
#       s/new-session\b([[:space:]]+\})/NSPROTECTED\1/g
#       s/\bnew-session\b/{new-session}/g
#       s/NSPROTECTED/new-session/g
#     }' "$cfg"
#     sed -i -E '
#       s/command-prompt -p new-session\b/command-prompt -p NSPROTECTED2/g
#       s/new-session\b( -s)/NSPROTECTED2\1/g
#       s/\bnew-session\b/command-prompt -p new-session "new-session -s '\''%%'\''"/g
#       s/NSPROTECTED2/new-session/g
#     ' "$cfg"
#   else
#     sed -i -E 's/\bcommand-prompt[[:space:]]+-p[[:space:]]+new-session[[:space:]]+"new-session[[:space:]]+-s[[:space:]]+'\''%%'\''"/new-session/g' "$cfg"
#   fi
EOF

# --- _apply_bindings(): new-session current-path retention -- if-branch
# (wrap) and else-branch (unwrap, for idempotent re-toggling) converted
# together since the shared `perl -p -i -e "` opener line between them isn't
# a unique grep anchor on its own. The if-branch's perl original uses a
# negative lookbehind "(?<!\bcommand-prompt -p )" to avoid touching the
# *label* text in a `command-prompt -p new-session "new-session ..."` wrap
# (added by the new-session-prompt feature above) while still adding
# `-c '#{pane_current_path}'` to the actual new-session *command* nested
# inside that same line. POSIX sed/awk have no lookbehind, so replicate with
# a protect/restore trick: temporarily swap out the literal
# "command-prompt -p new-session" label text, do the unconditional
# substitution, then swap the label back in -- empirically verified against
# both the plain-binding and prompt-wrapped cases in a container test. The
# else-branch's perl original strips a previously-added `-c <quote>#{pane_current_path}<quote>`
# flag back off (undoing the if-branch's own wrap when the feature is
# toggled off), tolerating 3 quote styles (', ", or \") via a captured
# alternation + backreference so open/close quotes match symmetrically --
# empirically verified against all 3 styles plus the bare-binding no-op case
# in a container test (busybox sed's ERE needs a literal backslash matched as
# \\\\ before an unescaped \" for the doubly-escaped-quote style). ---
replace_range 'if ! _is_disabled "$tmux_conf_new_session_retain_current_path" && _is_true "$tmux_conf_new_session_retain_current_path"; then' 9 <<'EOF'
#   if ! _is_disabled "$tmux_conf_new_session_retain_current_path" && _is_true "$tmux_conf_new_session_retain_current_path"; then
#     sed -i -E "
#       s/command-prompt -p new-session/command-prompt -p @@NS@@/g
#       s/\bnew-session\b/new-session -c '#{pane_current_path}'/g
#       s/command-prompt -p @@NS@@/command-prompt -p new-session/g" \
#       "$cfg"
#   else
#     sed -i -E "s/\bnew-session\b([^;}]*)[[:space:]]+-c[[:space:]]+(\\\\\"|\"|')?#\{pane_current_path\}\2/new-session\1/g" "$cfg"
#   fi
EOF

# --- sed/awk/perl availability check: drop perl from the list of required
# commands, since it's no longer needed by this file. Both occurrences get
# the same edit, so a global (non-anchored) substitution is simplest and is
# immune to line drift by construction. ---
grep -qF 'for cmd in perl sed awk; do' "$f" || { echo "rewrite-perl.sh: expected text not found (upstream ohmytmux may have changed): for cmd in perl sed awk; do" >&2; exit 1; }
sed -i 's/for cmd in perl sed awk; do/for cmd in sed awk; do/g' "$f"

# --- server-version check, duplicate of _tmux_version()'s parser ---
replace_line "_tmux_server_version=\$(tmux display -p '#{version}' | perl -n -e" <<'EOF'
#   _tmux_server_version=$(tmux display -p '#{version}' | awk '{ s=$0; sub(/^[^0-9]+/,"",s); sub(/[-+].*/,"",s); match(s,/^[0-9.]+/); n=substr(s,RSTART,RLENGTH); r=substr(s,RSTART+RLENGTH,1); if (r !~ /[a-z]/) r=""; printf "%d\n", n*1000 + (r=="" ? 0 : index("abcdefghijklmnopqrstuvwxyz", r)) }')
EOF

# --- _maximize_pane(): unrelated to perl removal, but fixed alongside it --
# `new-window -P "<shell-command>"` runs its argument as the new pane's
# process via `default-shell`, which in this config resolves to fish (the
# user's interactive login shell), not a POSIX shell. Every other dynamic
# shell invocation in this file (status-bar #{...} expansion, background
# refresh loops, TPM triggers) goes through `run-shell`/`run -b`, which
# always executes via a POSIX shell regardless of `default-shell` (verified
# empirically) -- this is the only site using new-window/split-window's raw
# pane-command argument, so it is the only one affected. Wrap it in an
# explicit `@bash@ -c '...'` invocation. The trailing `'$current_pane'` is
# kept OUTSIDE the bash -c argument (it's an unused, vestigial printf arg
# upstream -- its only real purpose is to leave a regex-detectable
# '%<pane_id>' token at the end of #{pane_start_command} for this same
# function's `restore=` detection sed below); keeping it outside means the
# wrapped script text needs no nested-quote escaping, and the detection
# regex's expected trailing pattern is preserved byte-for-byte. ---
replace_line "Pane has been maximized, press <prefix>+ to restore" <<'EOF'
#     info=$(tmux new-window -t "$current_session:" -F "#{session_name}:#{window_index}.#{pane_id}" -P "@bash@ -c 'maximized... 2>/dev/null & \"$TMUX_PROGRAM\" ${TMUX_SOCKET:+-S \"$TMUX_SOCKET\"} setw -t \"$current_session:\" remain-on-exit on; printf \"\\033[\$(tput lines);0fPane has been maximized, press <prefix>+ to restore\n\"' '$current_pane'")
EOF

# --- _blank(): last remaining perl call site. Computes a run of spaces with
# the same *visual terminal width* as $1 (used to pad the status bar when the
# prefix/mouse indicator is inactive, so its width doesn't shift when the
# indicator toggles). Replaced with a tiny compiled helper (@blank@, built
# from blank.c via glibc's wcwidth()) instead of a sed/awk translation --
# unlike every other site in this file, this one needs real Unicode
# character-width classification (combining marks -> 0 columns, East Asian
# wide/fullwidth -> 2 columns), which has no practical POSIX shell
# equivalent. wcwidth() reproduces perl's \p{M}/\p{EA=W,F} classification
# exactly for every case tested (ASCII, CJK, fullwidth Latin, combining
# marks, astral emoji) except zero-width format characters like U+200B
# (category Cf, not M) -- wcwidth treats those as 0-width where perl's
# \p{M}-only test would give them 1 space; accepted as a deliberate,
# documented divergence (arguably more correct for actual rendering; not
# relevant to the short decorative theme-icon strings this function is
# ever called on in practice). ---
replace_line "perl -CS -pe 's/\\p{M}//g; s/[\\p{EA=W}\\p{EA=F}]/  /g; s/./ /g'" <<'EOF'
#   printf '%s' "$1" | @blank@
EOF
