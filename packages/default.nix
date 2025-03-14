final: prev: {
  mypkg = {
    nvim = final.unstable.callPackage ./nvim { };
    clangd = final.unstable.callPackage ./clangd { clangd-src = final.clangd-src; };
    tmux = final.unstable.callPackage ./tmux { ohmytmux = final.ohmytmux; };
    myfish = final.unstable.callPackage ./fish { };
  };
}
