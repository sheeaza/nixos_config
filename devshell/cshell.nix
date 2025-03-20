pkgs:
let
  cshell = pkgs.buildEnv {
    name = "cshell";
    paths = [
      pkgs.unstable.neovim

      pkgs.tree
      pkgs.ripgrep
      pkgs.tig
      pkgs.git
      pkgs.unstable.fzf
    ];
  };
in
cshell
