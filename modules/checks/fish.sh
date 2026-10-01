#!/usr/bin/env bash
# Regression tests for the wrapped fish (packages.myfish).
#
# Each assertion corresponds either to something that actually broke at some
# point, or to a load-bearing assumption invisible at build time: the package
# builds fine either way, so only running fish catches a regression.
#
# Covered history:
#   483ed5d/86548ef/540fb22  fzf Ctrl-R field layout churn
#   934a581/68f34b6          Ctrl-T listing the wrong files
#   d46e4a4                  switch to upstream key-bindings.fish, --with-nth=3..
#   c60b635                  drop man-db from the closure
#
# Environment supplied by checks.nix:
#   LIB            path to lib.sh
#   FISH           the wrapped fish binary
#   FISH_CLOSURE   closureInfo store-paths manifest for myfish
set -u

# shellcheck source=lib.sh
. "$LIB"

# fish writes history and config under $HOME; without this it targets a
# non-existent homedir and the startup noise pollutes the assertions.
export HOME=$TMPDIR
mkdir -p "$HOME"

# The vendor bundle holds the autoloaded functions and the startup conf.d files.
# Resolved from the wrapper's own --init-command rather than hardcoded, since its
# store path changes on every edit.
bundle=$(sed -n 's#.*--prepend fish_function_path \(/nix/store/[^ ]*\)/share/fish/vendor_functions.d.*#\1#p' "$FISH" | head -1)
require "could not locate the vendor bundle in $FISH" "$bundle"

section 'startup is silent'
# A stray error in vendor_conf.d still yields a usable shell, so this is only
# ever visible by watching stderr. This is the assertion that caught fzf being
# absent from PATH.
startup_err=$("$FISH" -c 'true' 2>&1 >/dev/null)
assert_eq 'no output on stderr during startup' "" "$startup_err"

section 'environment (load-env.fish)'
assert_eq 'EDITOR is nvim'            "nvim"             "$("$FISH" -c 'echo $EDITOR')"
assert_eq 'TERM is xterm-256color'    "xterm-256color"   "$("$FISH" -c 'echo $TERM')"

section 'fzf Ctrl-T uses ripgrep (934a581, 68f34b6)'
ctrl_t=$("$FISH" -c 'echo "$FZF_CTRL_T_COMMAND"')
# fzf's built-in walker ignores .gitignore, which buries a project's own files
# under build output; rg replaces it.
assert_contains 'Ctrl-T command calls rg'            "$ctrl_t" "/bin/rg"
assert_contains 'Ctrl-T command uses an abs rg path' "$ctrl_t" "/nix/store/"
assert_contains 'Ctrl-T lists files'                 "$ctrl_t" "--files"
assert_contains 'Ctrl-T includes hidden files'       "$ctrl_t" "--hidden"
assert_contains 'Ctrl-T follows symlinks'            "$ctrl_t" "--follow"
assert_contains 'Ctrl-T excludes .git'               "$ctrl_t" "!.git/*"
# 68f34b6 removed a `sed 1d` that had been eating a real result: with rg --files
# there is no header line to strip.
assert_not_contains 'Ctrl-T does not delete first line' "$ctrl_t" "1d"

section 'fzf Ctrl-R shows only the command (d46e4a4)'
# `history --show-time` emits date<TAB>epoch<TAB>command. Upstream displays 2..,
# which leads every row with a bare epoch number; 3.. is the command alone.
assert_eq 'Ctrl-R opts override --with-nth to 3..' \
    "--with-nth=3.." "$("$FISH" -c 'echo "$FZF_CTRL_R_OPTS"')"

# That override only works because FZF_CTRL_R_OPTS is interpolated *after*
# upstream's own --with-nth and the last flag wins. If upstream ever moves the
# interpolation earlier, the variable above would still look right while the
# display silently regressed -- so assert the ordering, not just the value.
kb=$bundle/share/fish/vendor_conf.d/key_bindings.fish
assert_file_exists 'upstream key_bindings.fish is in vendor_conf.d' "$kb"
upstream_line=$(grep -n -- '--with-nth=2\.\.' "$kb" | head -1 | cut -d: -f1)
ours_line=$(grep -n -- 'FZF_CTRL_R_OPTS' "$kb" | tail -1 | cut -d: -f1)
if [ -n "$upstream_line" ] && [ -n "$ours_line" ] && [ "$ours_line" -gt "$upstream_line" ]; then
    ok 'FZF_CTRL_R_OPTS is interpolated after upstream --with-nth'
else
    bad 'FZF_CTRL_R_OPTS is interpolated after upstream --with-nth'
    printf '        upstream --with-nth at line [%s], ours at [%s]\n' "$upstream_line" "$ours_line"
fi

# --accept-nth governs the value handed back to the command line. It must stay
# 3.. regardless of what is displayed, or the epoch gets pasted too (86548ef).
assert_eq 'upstream returns only the command' \
    "--accept-nth=3.." "$(grep -o -- '--accept-nth=[0-9.]*' "$kb" | head -1)"

section 'fzf key bindings are installed (483ed5d, d46e4a4)'
# key_bindings.fish lives in conf.d, not functions.d: autoloading keys on
# filename == function name, but upstream's function is fzf_key_bindings, so it
# would never be found there.
binds=$("$FISH" -c 'bind' 2>/dev/null)
assert_contains 'ctrl-t is bound to fzf-file-widget'    "$binds" "ctrl-t fzf-file-widget"
assert_contains 'ctrl-r is bound to fzf-history-widget' "$binds" "ctrl-r fzf-history-widget"

section 'autoloaded functions resolve'
for fn in l la ll lla git-root fish_prompt fzf_key_bindings; do
    assert_eq "function '$fn' is defined" "function" "$("$FISH" -c "type -t $fn" 2>&1)"
done

section 'fish_prompt renders'
# The prompt shells out to sed; with a wrong path it would still "work" but
# silently lose its cwd and git segments.
prompt=$(cd "$HOME" && "$FISH" -c 'fish_prompt' 2>"$TMPDIR/prompt_err")
assert_eq 'fish_prompt writes nothing to stderr' "" "$(cat "$TMPDIR/prompt_err")"
assert_contains 'fish_prompt abbreviates $HOME to ~' "$prompt" "~"
assert_contains 'fish_prompt emits its prompt char'  "$prompt" "⟩"

section 'fish_prompt git segment'
# Exercise _git_branch_name/_git_is_dirty against a real repo: both pipe through
# sed, and neither runs at all outside a work tree.
repo=$TMPDIR/repo
mkdir -p "$repo"
git -C "$repo" init -q -b trunk
git -C "$repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
clean_prompt=$(cd "$repo" && "$FISH" -c 'fish_prompt' 2>"$TMPDIR/git_err")
assert_eq 'git segment writes nothing to stderr' "" "$(cat "$TMPDIR/git_err")"
# sed strips the refs/heads/ prefix; a broken sed path would leak it.
assert_contains     'prompt shows the branch name'       "$clean_prompt" "trunk"
assert_not_contains 'prompt strips refs/heads/'          "$clean_prompt" "refs/heads/"
assert_not_contains 'a clean tree has no dirty mark'     "$clean_prompt" "±"

echo hello > "$repo/f"
git -C "$repo" add f
git -C "$repo" -c user.email=t@t -c user.name=t commit -q -m f
echo changed >> "$repo/f"
dirty_prompt=$(cd "$repo" && "$FISH" -c 'fish_prompt' 2>/dev/null)
assert_contains 'a dirty tree is marked with ±' "$dirty_prompt" "±"

section 'fish_prompt sed is an absolute store path'
# A bare `sed` here would resolve against the user's PATH at runtime.
fp=$bundle/share/fish/vendor_functions.d/fish_prompt.fish
assert_file_exists 'fish_prompt.fish is autoloadable' "$fp"
if grep -qE '\| */nix/store/[^ ]*/bin/sed ' "$fp"; then
    ok 'fish_prompt pipes to an absolute sed'
else
    bad 'fish_prompt pipes to an absolute sed'
    grep -n 'sed' "$fp" | sed 's/^/        /'
fi

section 'closure stays slim (c60b635)'
assert_closure_lacks 'man-db is absent from the fish closure' \
    "$FISH_CLOSURE/store-paths" 'man-db-[0-9][^/]*'

finish check-fish
