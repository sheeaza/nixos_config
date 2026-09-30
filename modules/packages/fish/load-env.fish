set -gx EDITOR nvim
set -gx TERM xterm-256color

# Ctrl-T file list. fzf's built-in walker ignores .gitignore, which buries a
# project's own files under build output, so drive it from rg instead. Upstream's
# fzf-file-widget pipes this command into fzf when it is set.
# Deliberately -g and not -gx: the widget runs inside fish and reads it as a shell
# variable, so exporting it would only push it into the environment of every child
# process for no benefit.
set -g FZF_CTRL_T_COMMAND "@rg@ --follow --files --hidden --glob '!.git/*'"

# Ctrl-R rows. `builtin history --show-time` emits three tab-separated fields:
# human date, raw epoch seconds, then the command. Upstream displays --with-nth=2..,
# which leads every row with the bare epoch number. Show only the command instead.
# This is display-only: upstream's --accept-nth=3.. already returns just the command,
# and the preview/delete bindings address fields explicitly ({1}, {sf3..}).
# FZF_CTRL_R_OPTS is appended after upstream's own options and the last --with-nth
# wins, so this overrides the default without patching the bindings file.
# alt-t still cycles the display: command only -> epoch+command -> date+command.
set -g FZF_CTRL_R_OPTS "--with-nth=3.."
