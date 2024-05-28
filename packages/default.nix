{ clangd-src, ohmytmux, tele-src }:
final: prev: {
  mypkg = {
    nvim = final.unstable.callPackage ./nvim { inherit tele-src; };
    clangd = final.unstable.callPackage ./clangd { inherit clangd-src; };
    tmux = final.unstable.callPackage ./tmux { inherit ohmytmux; };
    myfish = final.unstable.callPackage ./fish { };
  };
}
