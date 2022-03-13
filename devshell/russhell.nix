pkgs:
let
  cshell = pkgs.buildEnv {
    name = "cshell";
    paths = [
      pkgs.busybox
      pkgs.less
      pkgs.ncurses

      pkgs.mypkg.nvim

      pkgs.bashInteractive

      pkgs.perl

      pkgs.wget
      pkgs.tree
      pkgs.ripgrep
      pkgs.tig
      pkgs.git
      pkgs.fzf
      pkgs.bash

      pkgs.rust-analyzer
      pkgs.rustc
      pkgs.cargo
    ];
  };
in
  cshell
