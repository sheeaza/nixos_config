{
  neovim,
  vimPlugins,
  vimUtils,
  stdenv,
}:
let
  treesitter = vimPlugins.nvim-treesitter.withAllGrammars;
  nviminit = vimUtils.buildVimPlugin {
    name = "nviminit";
    src = ./myconfig;
  };
  cocsetting = stdenv.mkDerivation {
    name = "coc-setting";
    src = ./.;
    phases = [
      "unpackPhase"
      "installPhase"
    ];
    # mkdir empty plugins to prevent error outputs
    installPhase = ''
      mkdir -p $out;
      cp $src/coc-settings.json $out/
    '';
  };
in
let
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
        lua vim.g.coc_config_home='${cocsetting}'
        lua require('nviminit')
      '';
    };
  };
in
nvim
