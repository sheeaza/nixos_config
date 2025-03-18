pkgs:
let
  cshell = pkgs.buildEnv {
    name = "cshell";
    paths = [
      pkgs.busybox
      pkgs.less
      pkgs.ncurses

      pkgs.unstable.neovim
      pkgs.unstable.clangd
      pkgs.universal-ctags

      pkgs.bashInteractive

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
