{
  internal.overlays.ov_rustshell = final: prev: {
    rustshell = final.buildEnv {
      name = "rustshell";
      paths = [
        final.findutils
        final.less
        final.coreutils
        final.gnused
        final.procps

        final.unstable.tmux
        final.unstable.fish
        final.unstable.neovim

        final.bashInteractive

        final.wget
        final.tree
        final.ripgrep
        final.tig
        final.git
        final.unstable.fzf
        final.bash

        # final.binutils
        # final.gcc
        # final.gdb
        # final.gdbgui
        final.clang
        final.rust-analyzer
        final.rustfmt
        final.rustc
        final.cargo
      ];
    };
  };
}
