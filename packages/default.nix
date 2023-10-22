inputs: final: prev:
let
in with final.unstable; {
  mypkg = {
    nvim = import ./nvim { pkgs = final; };
    clangd = import ./clangd { pkgs = final; clangd-src = inputs.clangd-src; };
    tmux = import ./tmux { pkgs = final; ohmytmux = inputs.ohmytmux; };
    myfish = import ./fish { pkgs = final; };
  };
}
