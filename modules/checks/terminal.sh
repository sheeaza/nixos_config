#!/usr/bin/env bash
# Regression tests for the wrapped alacritty (packages.myalacritty) and the niri
# config (packages.myniricfg).
#
# Both are pure config artifacts: the derivations only substitute a store path
# and copy a file, so they build successfully even when the result is malformed.
# Alacritty and niri each ship a real validator, and nothing in the build invokes
# either -- a broken config is only discovered on next login. These tests run the
# validators, and additionally pin the cross-package reference from niri's
# keybinding to the wrapped alacritty.
#
# Environment supplied by checks.nix:
#   LIB         path to lib.sh
#   ALACRITTY   the wrapped alacritty binary
#   NIRI_CFG    the substituted config.kdl
#   NIRI_BIN    upstream niri, for `niri validate`
#   ALAC_WRAPPED_BIN  the wrapped alacritty that niri's config should point at
set -u

# shellcheck source=lib.sh
. "$LIB"

export HOME=$TMPDIR
mkdir -p "$HOME"

section 'alacritty config is wired into the wrapper'
# The config reaches alacritty only via a baked --config-file flag; without it
# alacritty silently falls back to its own defaults.
cfg=$(sed -n 's/.*--config-file \([^ ]*\.toml\).*/\1/p' "$(readlink -f "$ALACRITTY")" | head -1)
require "could not find a baked --config-file in $ALACRITTY" "$cfg"
assert_file_exists 'the baked alacritty.toml exists' "$cfg"
assert_no_placeholders 'alacritty.toml has no unsubstituted @markers@' "$cfg"

section 'alacritty parses its own config'
# `migrate --dry-run` is alacritty's config parser: it exits non-zero on a TOML
# syntax error or an unknown key, without needing a display.
alac_out=$("$ALACRITTY" migrate --dry-run --config-file "$cfg" 2>&1)
assert_rc_zero 'alacritty accepts the config' "$?" "$alac_out"
# The validator reports "Skipping migration for nonexistent path" instead of
# failing when an import is missing, so a dangling theme path would otherwise
# pass silently.
assert_not_contains 'no imports were skipped as nonexistent' "$alac_out" "nonexistent path"

section 'alacritty theme import resolves'
theme=$(sed -n 's/^[[:space:]]*"\(\/nix\/store\/[^"]*\.toml\)".*/\1/p' "$cfg" | head -1)
require "could not find an imported theme path in $cfg" "$theme"
assert_file_exists 'the imported one_dark theme exists' "$theme"
# The import is what supplies every colour; alacritty runs fine without it.
assert_contains 'the theme defines primary colours' \
    "$(cat "$theme")" "[colors.primary]"

section 'alacritty settings survive the substitution'
cfg_body=$(cat "$cfg")
assert_contains 'window decorations are disabled' "$cfg_body" 'decorations           = "None"'
assert_contains 'the nerd font is selected'       "$cfg_body" 'family = "Hack Nerd Font"'
assert_contains 'F11 toggles fullscreen'          "$cfg_body" 'action = "ToggleFullscreen"'
# Ctrl+Shift+F/B are deliberately passed through to the application (tmux) as
# ReceiveChar rather than being eaten by alacritty.
assert_contains 'ctrl-shift-F is passed through'  "$cfg_body" '{ key = "F", mods = "Control|Shift", action = "ReceiveChar"}'
assert_contains 'ctrl-shift-B is passed through'  "$cfg_body" '{ key = "B", mods = "Control|Shift", action = "ReceiveChar"}'

section 'niri config is valid KDL'
assert_file_exists 'the substituted config.kdl exists' "$NIRI_CFG"
# @DEFAULT_AUDIO_SINK@/@DEFAULT_AUDIO_SOURCE@ are wpctl's own syntax for the
# default device, passed through to spawn-sh verbatim -- not Nix placeholders.
assert_no_placeholders 'config.kdl has no unsubstituted @markers@' "$NIRI_CFG" \
    '^@DEFAULT_AUDIO_(SINK|SOURCE)@$'
# `niri validate` parses the KDL and typechecks every node, so it catches both a
# syntax slip and an unknown setting.
niri_out=$("$NIRI_BIN" validate --config "$NIRI_CFG" 2>&1)
niri_rc=$?
assert_rc_zero 'niri accepts the config' "$niri_rc" "$niri_out"
assert_contains 'niri reports the config as valid' "$niri_out" "config is valid"

section 'niri spawns the wrapped alacritty'
# This is the one genuinely cross-package assertion: config.kdl substitutes
# @alacritty@ with the *wrapped* alacritty, so the terminal niri launches is the
# one carrying the baked --config-file. A plain `alacritty` here would start an
# unconfigured terminal, and nothing at build time would notice.
kdl_body=$(cat "$NIRI_CFG")
assert_contains 'Mod+T spawns an absolute store path' "$kdl_body" 'spawn "/nix/store/'
assert_contains 'Mod+T spawns the wrapped alacritty' \
    "$kdl_body" "spawn \"$ALAC_WRAPPED_BIN\""
assert_executable 'the spawned alacritty is executable' "$ALAC_WRAPPED_BIN"

finish check-terminal
