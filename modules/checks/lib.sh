# shellcheck shell=bash
#
# Shared assertion vocabulary for the checks in this directory.
#
# Sourced, never executed. Every value a check needs is passed through the
# environment by checks.nix, so these scripts contain no Nix interpolation and
# can be read, shellchecked and run as ordinary shell.
#
# Assertions accumulate failures instead of aborting on the first one, so a
# single run reports every broken invariant rather than just the earliest.
# `finish` is what actually fails the derivation -- a check that forgets to call
# it passes vacuously.

fail=0
checks_run=0

ok() {
    checks_run=$((checks_run + 1))
    printf '  ok    %s\n' "$1"
}

bad() {
    checks_run=$((checks_run + 1))
    fail=1
    printf '  FAIL  %s\n' "$1"
}

section() {
    printf '\n== %s\n' "$1"
}

# assert_eq <desc> <expected> <actual>
assert_eq() {
    if [ "$2" = "$3" ]; then
        ok "$1"
    else
        bad "$1"
        printf '        expected: [%s]\n        actual:   [%s]\n' "$2" "$3"
    fi
}

# assert_contains <desc> <haystack> <needle>
assert_contains() {
    case "$2" in
        *"$3"*) ok "$1" ;;
        *)
            bad "$1"
            printf '        substring not found: [%s]\n        in:                  [%s]\n' "$3" "$2"
            ;;
    esac
}

# assert_not_contains <desc> <haystack> <needle>
assert_not_contains() {
    case "$2" in
        *"$3"*)
            bad "$1"
            printf '        unexpected substring: [%s]\n        in:                   [%s]\n' "$3" "$2"
            ;;
        *) ok "$1" ;;
    esac
}

# assert_file_exists <desc> <path>
assert_file_exists() {
    if [ -f "$2" ]; then
        ok "$1"
    else
        bad "$1"
        printf '        no such file: [%s]\n' "$2"
    fi
}

# assert_executable <desc> <path>
assert_executable() {
    if [ -x "$2" ]; then
        ok "$1"
    else
        bad "$1"
        printf '        not executable: [%s]\n' "$2"
    fi
}

# assert_rc_zero <desc> <rc> [output]
assert_rc_zero() {
    if [ "$2" -eq 0 ]; then
        ok "$1"
    else
        bad "$1"
        printf '        exit status: %s\n' "$2"
        [ -n "${3:-}" ] && printf '%s\n' "$3" | sed 's/^/        /'
    fi
}

# assert_no_placeholders <desc> <file> [extra-allowed-regex]
#
# The packages substitute @name@ markers with store paths at build time. A typo
# in a substitution name leaves the marker in place, and because
# replaceVars/substitute only hard-fail on --replace-fail entries, a stale marker
# can otherwise ship silently and only break at runtime.
#
# Some configs legitimately contain @...@ that is another tool's own syntax
# (wpctl's @DEFAULT_AUDIO_SINK@, for instance). Pass an extended regex as the
# third argument to exempt those.
assert_no_placeholders() {
    local left
    left=$(grep -oE '@[a-zA-Z_][a-zA-Z0-9_-]*@' "$2" | sort -u)
    if [ -n "${3:-}" ]; then
        left=$(printf '%s\n' "$left" | grep -vE "$3" || true)
    fi
    left=$(printf '%s' "$left" | tr '\n' ' ')
    if [ -n "${left// /}" ]; then
        bad "$1"
        printf '        unsubstituted markers: %s\n' "$left"
    else
        ok "$1"
    fi
}

# assert_closure_lacks <desc> <store-paths file> <extended regex>
#
# Reads a closureInfo manifest rather than calling `nix path-info`: checks run
# inside the build sandbox, where the nix daemon is unreachable.
assert_closure_lacks() {
    local hits
    if hits=$(grep -oE "$3" "$2" | sort -u | tr '\n' ' '); [ -n "$hits" ]; then
        bad "$1"
        printf '        found in closure: %s\n' "$hits"
    else
        ok "$1"
    fi
}

# require <desc> <path>
#
# Hard precondition on the test rig itself, as opposed to the thing under test.
# If a check cannot locate its own inputs, every downstream assertion would pass
# vacuously, so bail loudly instead.
require() {
    if [ -z "$2" ] || [ ! -e "$2" ]; then
        printf 'FATAL: %s (got [%s])\n' "$1" "${2:-}" >&2
        exit 1
    fi
}

# finish <name> -- fail the build if any assertion failed.
finish() {
    printf '\n'
    if [ "$fail" -ne 0 ]; then
        printf '%s: FAILED (%s assertions run)\n' "$1" "$checks_run"
        exit 1
    fi
    printf '%s: all %s assertions passed\n' "$1" "$checks_run"
    # $out comes from the Nix builder environment, not from these scripts.
    # shellcheck disable=SC2154
    echo "$1 ok" > "$out"
}
