{
  internal.unstableOverlays.cus-nvim =
    final: _prev:
    let
      fzf-lua-cfg = final.replaceVars ./myconfig/lua/fzf_lua.lua {
        rg = "${final.ripgrep}/bin/rg";
        fzf = "${final.fzf}/bin/fzf";
        ctag = "${final.universal-ctags}/bin/ctags";
      };
      lsp-cfg = final.replaceVars ./myconfig/lua/lsp_cfg.lua {
        clangd = "${final.cus-clangd}/bin/clangd";
      };

      # treesitter = final.vimPlugins.nvim-treesitter.withAllGrammars; #this will cause lag
      treesitter = final.vimPlugins.nvim-treesitter.withPlugins (p: [
        # these are mandatory,
        p.c
        p.lua
        p.vimdoc

        p.rust
        p.cpp
      ]);

      nviminit = final.vimUtils.buildVimPlugin {
        name = "nviminit";
        src = ./myconfig;
        postInstall = ''
          cp ${fzf-lua-cfg} $out/lua/fzf_lua.lua
          cp ${lsp-cfg} $out/lua/lsp_cfg.lua
        '';
        dependencies = with final.vimPlugins; [
          lualine-nvim
          onedark-nvim
          flash-nvim
          treesitter
          fzf-lua
          blink-cmp
        ];
      };
    in
    {
      cus-nvim = final.neovim.override {
        withPython3 = false;
        withRuby = false;
        configure = {
          packages.mypack.start = [
            final.vimPlugins.nerdcommenter
            nviminit
          ];
          customRC = ''
            lua require('nviminit')
          '';
        };
      };
    };

  internal.unstableOverlays.headless-nvim = final: _prev: {
    neovim-headless = final.cus-nvim.override { waylandSupport = false; };
  };

  perSystem = { pkgs, ... }: {
    packages.mynvim = pkgs.unstable.cus-nvim;
  };
}
