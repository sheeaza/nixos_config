pkgs:
let
  cshell = pkgs.buildEnv {
    name = "cshell";
    paths = [
      pkgs.findutils
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

      pkgs.clang_13
      pkgs.rust-analyzer
      pkgs.rustfmt
      pkgs.rustc
      pkgs.cargo
    ];
  };
in
  cshell
