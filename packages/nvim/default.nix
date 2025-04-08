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
  fzf,
}:
let
  fzf-lua-cfg = substituteAll {
    src = ./myconfig/lua/fzf_lua.lua;
    rg = "${ripgrep}/bin/rg";
    fzf = "${fzf}/bin/fzf";
    ctag = "${universal-ctags}/bin/ctags";
  };
  lsp-cfg = substituteAll {
    src = ./myconfig/lua/lsp_cfg.lua;
    clangd = "${clangd}/bin/clangd";
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
      cp ${fzf-lua-cfg} $out/lua/fzf_lua.lua
      cp ${lsp-cfg} $out/lua/lsp_cfg.lua
    '';
    dependencies = with vimPlugins; [
      lualine-nvim
      onedark-nvim
      flash-nvim
      treesitter
      fzf-lua
      blink-cmp
    ];
  };
in
let
  nvim = neovim.override {
    withNodeJs = false;
    withRuby = false;
    configure = {
      packages.mypack = with vimPlugins; {
        start = [
          nerdcommenter
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
