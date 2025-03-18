final: prev: {
  neovim = prev.callPackage ./nvim { neovim = prev.neovim; };
  clangd = prev.callPackage ./clangd { clangd-src = final.clangd-src; };
  tmux = prev.callPackage ./tmux { ohmytmux = final.ohmytmux; tmux = prev.tmux; };
  fish = prev.callPackage ./fish { wrapFish = prev.wrapFish; };
}
