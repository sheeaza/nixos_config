inputs: final: prev:
let
  nvim = import ./nvim { pkgs = final; leaderf-src = inputs.leaderf-src; };
  clangd = import ./clangd { pkgs = final; clangd-src = inputs.clangd-src; };
  tmux = import ./tmux { pkgs = final; ohmytmux = inputs.ohmytmux; };
  myfish = import ./fish { pkgs = final; };
in with final.unstable; {
  mypkg = buildEnv {
    name = "devpack";
    paths = [
      nvim
      clangd
      global
      universal-ctags

      tmux
      perl

      myfish
      wget
      ripgrep
      tree
      tig
      git
      fzf

      coreutils
      findutils
      gnutar
      bash
    ];
  };
}
