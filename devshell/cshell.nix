pkgs:
let
  cshell = pkgs.buildEnv {
    name = "cshell";
    paths = [
      pkgs.busybox
      pkgs.less
      pkgs.ncurses

      pkgs.mypkg.nvim
      pkgs.mypkg.clangd
      pkgs.universal-ctags

      pkgs.bashInteractive
      pkgs.perl

      pkgs.wget
      pkgs.tree
      pkgs.ripgrep
      pkgs.tig
      pkgs.git
      pkgs.unstable.fzf
    ];
  };
in
cshell
