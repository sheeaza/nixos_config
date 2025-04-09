final: prev: {
  neovim = final.callPackage ./nvim { neovim = prev.neovim; };
  clangd = final.callPackage ./clangd { };
  tmux = final.callPackage ./tmux { tmux = prev.tmux; };
  myfish = final.callPackage ./fish { };
  tig = prev.tig.override {
    git = final.gitMinimal;
  };
}
