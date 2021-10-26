{ self, ... }@inputs:
let
  upkgs = inputs.upkgs.legacyPackages.x86_64-linux;
in 
  let
    nvim = import ./nvim { pkgs = upkgs; leaderf-src = inputs.leaderf-src; };
    clangd = import ./clangd { pkgs = upkgs; clangd-src = inputs.clangd-src; };
    tmux = import ./tmux { pkgs = upkgs; ohmytmux = inputs.ohmytmux; };
    myfish = import ./fish { pkgs = upkgs; };
  in
    upkgs.buildEnv {
      name = "devpack";
      paths = [
        nvim
        clangd
        upkgs.global
        upkgs.universal-ctags

        tmux
        upkgs.perl

        myfish
        upkgs.wget
        upkgs.ripgrep
        upkgs.tree
        upkgs.tig
        upkgs.git
        upkgs.fzf

        upkgs.coreutils
        upkgs.findutils
        upkgs.gnutar
        upkgs.bash
      ];
    }
