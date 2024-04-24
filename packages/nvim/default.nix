{ neovim, vimPlugins, vimUtils }:
let
  treesitter = vimPlugins.nvim-treesitter.withPlugins (
    plugins: with plugins; [
      tree-sitter-c
      tree-sitter-rust
    ]
  );
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
