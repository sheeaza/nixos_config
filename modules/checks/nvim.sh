#!/usr/bin/env bash
# Regression tests for the wrapped neovim (packages.mynvim).
#
# The config is assembled from a vimUtils plugin built out of ./myconfig, with
# two lua files rewritten at build time to bake in absolute store paths
# (fzf_lua.lua, lsp_cfg.lua). Nothing here fails the build if a plugin stops
# loading or a substitution goes stale -- nvim starts anyway and the feature is
# just quietly gone -- so these assertions all run a real headless nvim and read
# the resulting state back out.
#
# Environment supplied by checks.nix:
#   LIB            path to lib.sh
#   NVIM           the configured nvim binary
#   NVIM_CLOSURE   closureInfo store-paths manifest for mynvim
set -u

# shellcheck source=lib.sh
. "$LIB"

export HOME=$TMPDIR
mkdir -p "$HOME"

# Run a lua snippet in headless nvim and echo whatever it writes to stdout.
# `-c qa!` keeps each invocation from hanging on the alternate screen.
nv_lua() { "$NVIM" --headless -c "lua $1" -c 'qa!' 2>/dev/null; }

section 'headless startup is clean'
# customRC does `lua require('nviminit')`, which pulls in every other module. A
# lua error anywhere in that chain prints here and nowhere else -- nvim still
# exits 0 and still "works", just without the broken module's settings.
startup_err=$("$NVIM" --headless -c 'qa!' 2>&1)
assert_eq 'no output on stderr during startup' "" "$startup_err"

section 'options from nviminit.lua'
# Indentation is the setting most likely to be silently clobbered by a plugin
# loaded after nviminit, so assert the resolved values rather than the source.
assert_eq 'tabstop is 4'           "4"    "$(nv_lua 'io.write(vim.o.tabstop)')"
assert_eq 'shiftwidth is 4'        "4"    "$(nv_lua 'io.write(vim.o.shiftwidth)')"
assert_eq 'softtabstop is 4'       "4"    "$(nv_lua 'io.write(vim.o.softtabstop)')"
assert_eq 'expandtab is on'        "true" "$(nv_lua 'io.write(tostring(vim.o.expandtab))')"
assert_eq 'colorcolumn is 80'      "80"   "$(nv_lua 'io.write(vim.o.colorcolumn)')"
assert_eq 'relativenumber is on'   "true" "$(nv_lua 'io.write(tostring(vim.o.relativenumber))')"
assert_eq 'number is on'           "true" "$(nv_lua 'io.write(tostring(vim.o.number))')"
assert_eq 'termguicolors is on'    "true" "$(nv_lua 'io.write(tostring(vim.o.termguicolors))')"
assert_eq 'laststatus is global'   "3"    "$(nv_lua 'io.write(vim.o.laststatus)')"
assert_eq 'ignorecase is on'       "true" "$(nv_lua 'io.write(tostring(vim.o.ignorecase))')"
assert_eq 'smartcase is on'        "true" "$(nv_lua 'io.write(tostring(vim.o.smartcase))')"
# Deliberately disabled: the config sets mouse to the empty string.
assert_eq 'mouse is disabled'      ""     "$(nv_lua 'io.write(vim.o.mouse)')"

section 'plugins load'
# `start` plugins are on the runtimepath, but a plugin whose own setup() throws
# leaves require() failing while nvim still starts fine.
for mod in fzf-lua lualine flash blink.cmp nvim-treesitter onedark nerdcommenter; do
    case $mod in
        # nerdcommenter is a vimscript plugin with no lua module; probe the
        # global it defines instead.
        nerdcommenter)
            assert_eq "$mod is loaded" "1" \
                "$(nv_lua 'io.write(vim.fn.exists("g:loaded_nerd_comments"))')"
            ;;
        *)
            assert_eq "module '$mod' loads" "true" \
                "$(nv_lua "io.write(tostring((pcall(require, '$mod'))))")"
            ;;
    esac
done

section 'treesitter grammars are built in'
# The config deliberately pins a small grammar set rather than withAllGrammars,
# which was causing lag. Assert exactly those parsers are present.
for lang in c lua vimdoc rust cpp; do
    assert_eq "the $lang parser is available" "true" \
        "$(nv_lua "io.write(tostring(vim.treesitter.language.add('$lang')))")"
done

section 'baked store paths (fzf_lua.lua, lsp_cfg.lua)'
# These three are @markers@ substituted at build time. A stale marker or a
# relative name would only surface the first time the feature is used.
clangd_cmd=$(nv_lua 'io.write(vim.lsp.config.clangd.cmd[1])')
assert_contains 'clangd is an absolute store path' "$clangd_cmd" "/nix/store/"
assert_contains 'clangd points at a clangd binary' "$clangd_cmd" "/bin/clangd"
assert_executable 'the configured clangd exists'   "$clangd_cmd"

# fzf-lua keeps the configured binary in its own resolved options table.
fzf_bin=$(nv_lua 'io.write(require("fzf-lua").config.globals.fzf_bin or "")')
assert_contains 'fzf_bin is an absolute store path' "$fzf_bin" "/nix/store/"
assert_executable 'the configured fzf exists'       "$fzf_bin"

section 'clangd LSP wiring (lsp_cfg.lua)'
assert_contains 'clangd runs with --background-index' \
    "$(nv_lua 'io.write(table.concat(vim.lsp.config.clangd.cmd, " "))')" "--background-index"
assert_contains 'clangd roots on compile_commands.json' \
    "$(nv_lua 'io.write(table.concat(vim.lsp.config.clangd.root_markers, " "))')" "compile_commands.json"
assert_contains 'clangd handles c and cpp' \
    "$(nv_lua 'io.write(table.concat(vim.lsp.config.clangd.filetypes, " "))')" "cpp"

section 'user commands'
# Fzfgrep/Fzffile are defined in fzf_lua.lua and wrap the baked rg path;
# TrimWhitespace comes from nviminit.lua.
for cmd in Fzfgrep Fzffile TrimWhitespace; do
    assert_eq "command :$cmd is defined" "true" \
        "$(nv_lua "io.write(tostring(vim.api.nvim_get_commands({})['$cmd'] ~= nil))")"
done

section 'keymaps'
# gd/gr route through fzf-lua rather than the stock LSP handlers, and lsp_cfg.lua
# deletes neovim's default gr* maps to free them. If those deletions ever run
# before the maps exist, startup errors -- which the stderr check above catches.
has_map() {
    nv_lua "local m = vim.fn.maparg('$1', '$2'); io.write(tostring(m ~= nil and m ~= ''))"
}
assert_eq 'gd is mapped in normal mode'   "true" "$(has_map gd n)"
assert_eq 'gr is mapped in normal mode'   "true" "$(has_map gr n)"
assert_eq 'gh is mapped for hover'        "true" "$(has_map gh n)"
assert_eq '<F2> is mapped for rename'     "true" "$(has_map '<F2>' n)"

section 'filetype autocmds'
# nviminit.lua forces *.h to c rather than letting nvim guess cpp.
touch "$TMPDIR/probe.h"
assert_eq '*.h opens as c, not cpp' "c" \
    "$("$NVIM" --headless "$TMPDIR/probe.h" -c 'lua io.write(vim.bo.filetype)' -c 'qa!' 2>/dev/null)"

section 'closure stays slim'
# The override sets withPython3 = false and withRuby = false; both would
# otherwise drag a full interpreter into the closure.
assert_closure_lacks 'python3 is absent from the nvim closure' \
    "$NVIM_CLOSURE/store-paths" 'python3-[0-9][^/]*'
assert_closure_lacks 'ruby is absent from the nvim closure' \
    "$NVIM_CLOSURE/store-paths" 'ruby-[0-9][^/]*'

finish check-nvim
