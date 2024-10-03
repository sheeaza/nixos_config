{
  neovim,
  vimPlugins,
  vimUtils,
  stdenv,
  lua-language-server,
  substituteAll,
}:
let
  coccfg = substituteAll {
    src = ./coc-settings.json;
    luals = "${lua-language-server}";
  };
in
let
  # treesitter = vimPlugins.nvim-treesitter.withAllGrammars; #this will cause lag
  treesitter = vimPlugins.nvim-treesitter.withPlugins (p: [
    # these are mandatory,
    p.c
    p.lua
    p.vimdoc

    p.rust
    p.cpp
  ]);
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
      cp ${coccfg} $out/coc-settings.json
    '';
  };
in
let
  nvim = neovim.override {
    withNodeJs = true;
    withRuby = false;
    configure = {
      packages.mypack = with vimPlugins; {
        start = [
          lualine-nvim
          onedark-nvim
          nerdcommenter
          treesitter
          coc-nvim
          coc-clangd
          coc-rust-analyzer
          coc-sumneko-lua
          LeaderF
          flash-nvim
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
