{ self, ... }@inputs:
let
  upkgs = inputs.upkgs.legacyPackages.x86_64-linux;
in 
  let
    nvim = import ./nvim { pkgs = upkgs; leaderf-src = inputs.leaderf-src; };
    tmux = import ./tmux { pkgs = upkgs; ohmytmux = inputs.ohmytmux; };
  in
    upkgs.buildEnv {
      name = "devpack";
      paths = [
        #nvim
        #upkgs.global
        #upkgs.clang-tools

        tmux
        upkgs.perl

        #upkgs.wget
        #upkgs.ripgrep
        #upkgs.tree
        #upkgs.tig
        #upkgs.universal-ctags
        upkgs.git
        upkgs.fzf
        upkgs.fish

        upkgs.coreutils
        upkgs.findutils
        #upkgs.gnutar
        #upkgs.tree
        upkgs.bash
      ];
    }
