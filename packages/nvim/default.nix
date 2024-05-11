{ neovim, vimPlugins, vimUtils }:
let
  treesitter = vimPlugins.nvim-treesitter.withAllGrammars;
  nviminit = vimUtils.buildVimPlugin {
    name = "nviminit";
    src = ./myconfig;
  };
in let
  nvim = neovim.override {
    withNodeJs = true;
    configure = {
      packages.mypack = with vimPlugins; {
        start = [
          lightline-vim
          onedark-vim
          nerdcommenter
          treesitter
          coc-nvim
          coc-clangd
          coc-rust-analyzer
          LeaderF
          vim-easymotion
          nviminit
        ];
      };
      customRC = ''
        lua require('nviminit')
      '';
    };
  };
in
  nvim
