pkgs:
pkgs.buildEnv {
  name = "rustshell";
  paths = [
    pkgs.findutils
    pkgs.less
    pkgs.ncurses
    pkgs.coreutils
    pkgs.gnused
    pkgs.procps

    pkgs.mypkg.tmux
    pkgs.mypkg.myfish
    pkgs.mypkg.nvim

    pkgs.bashInteractive

    pkgs.perl

    pkgs.wget
    pkgs.tree
    pkgs.ripgrep
    pkgs.tig
    pkgs.git
    pkgs.unstable.fzf
    pkgs.bash

    # pkgs.binutils
    # pkgs.gcc
    # pkgs.gdb
    # pkgs.gdbgui
    pkgs.clang
    pkgs.rust-analyzer
    pkgs.rustfmt
    pkgs.rustc
    pkgs.cargo
  ];
}
