inputs: final: prev: {
  mypkg = {
    nvim = final.unstable.callPackage ./nvim { };
    clangd =
      final.unstable.callPackage ./clangd { clangd-src = inputs.clangd-src; };
    tmux = final.unstable.callPackage ./tmux { ohmytmux = inputs.ohmytmux; };
    myfish = final.unstable.callPackage ./fish { };
  };
}
