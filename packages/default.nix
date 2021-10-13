{ self, ... }@inputs:
let
  upkgs = inputs.upkgs.legacyPackages.${system}
in 
  let
    nvim = import ./nvim { pkgs = upkgs; leaderf-src = inputs.leaderf-src; };
    tmux = import ./tmux { pkgs = upkgs; ohmytmux = inputs.ohmytmux; };
  in
    upkgs.buildEnv {
      name = "devpack";
      paths = [
        nvim
        tmux
        upkgs.fzf
        upkgs.clang-tools
        upkgs.wget
        upkgs.ripgrep
        upkgs.tree
        upkgs.tig
        upkgs.universal-ctags
        upkgs.global
        upkgs.git
        upkgs.fish
      ];
    }
