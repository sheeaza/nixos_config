{ clangd-src, ohmytmux }: final: prev: {
  mypkg = {
    nvim = final.unstable.callPackage ./nvim { };
    clangd =
      final.unstable.callPackage ./clangd { inherit clangd-src; };
    tmux = final.unstable.callPackage ./tmux { inherit ohmytmux; };
    myfish = final.unstable.callPackage ./fish { };
  };
}
