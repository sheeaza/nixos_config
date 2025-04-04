{
  neovim,
  vimPlugins,
  vimUtils,
  stdenv,
  lua-language-server,
  substituteAll,
  ripgrep,
  clangd,
  universal-ctags,
}:
let
  coccfg = substituteAll {
    src = ./coc-settings.json;
    luals = "${lua-language-server}";
    clangd = "${clangd}/bin/clangd";
  };
  leaderf-lua = substituteAll {
    src = ./myconfig/lua/leaderf.lua;
    rg = "${ripgrep}/bin/rg";
    ctags = "${universal-ctags}/bin/ctags";
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
    postInstall = ''
      cp ${leaderf-lua} $out/lua/leaderf.lua
    '';
    dependencies = with vimPlugins; [
      lualine-nvim
      onedark-nvim
      flash-nvim
      treesitter
    ];
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
          nerdcommenter
          coc-nvim
          coc-clangd
          coc-rust-analyzer
          coc-sumneko-lua
          LeaderF
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
