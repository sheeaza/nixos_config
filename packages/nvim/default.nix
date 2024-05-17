{
  neovim,
  vimPlugins,
  vimUtils,
}:
let
  treesitter = vimPlugins.nvim-treesitter.withAllGrammars;
  nviminit = vimUtils.buildVimPlugin {
    name = "nviminit";
    src = ./myconfig;
  };
in
let
  nvim = neovim.override {
    configure = {
      packages.mypack = with vimPlugins; {
        start = [
          lualine-nvim
          onedark-vim
          nerdcommenter
          treesitter

          nvim-lspconfig
          cmp-nvim-lsp
          cmp-buffer
          cmp-path
          cmp-cmdline
          nvim-cmp
          luasnip

          LeaderF
          telescope-nvim
          telescope-fzf-native-nvim
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
