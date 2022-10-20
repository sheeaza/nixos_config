{ pkgs, leaderf-src }: with pkgs.unstable;
let
  leaderf = vimUtils.buildVimPlugin {
    name = "leaderf";
    src = leaderf-src;
    buildInputs = [ python3 ];
    buildPhase = ''
      patchShebangs .
      ./install.sh
      rm autoload/leaderf/fuzzyMatch_C/build/ -r
      find ./ -type f -exec strip '{}' \; 2>/dev/null
    '';
  };
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
    configure = {
      packages.mypack = with vimPlugins; {
        start = [
          lightline-vim
          onedark-vim
          nerdcommenter
          treesitter

	  nvim-lspconfig
	  cmp-nvim-lsp
	  cmp-buffer
	  cmp-path
	  cmp-cmdline
	  nvim-cmp

          leaderf
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
