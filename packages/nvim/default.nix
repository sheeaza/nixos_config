{ pkgs, leaderf-src }: with pkgs.unstable;
let
  leaderf = vimUtils.buildVimPlugin {
    name = "leaderf";
    src = leaderf-src;
    buildInputs = [ python3 ];
    buildPhase = ''
      patchShebangs .
      ./install.sh
    '';
  };
  # gcc
  treesitter = vimPlugins.nvim-treesitter.withPlugins (
    plugins: with plugins; [
      tree-sitter-grammars.c
      tree-sitter-grammars.rust
    ]
  );
in
  let
    nvim = neovim.override {
      withNodeJs = true;
      configure = {
        plug.plugins = with vimPlugins; [
            lightline-vim
            onedark-vim
            nerdcommenter
	    treesitter
	    coc-nvim
	    coc-clangd
	    coc-rust-analyzer
	    leaderf
            vim-easymotion
        ];
        customRC = builtins.readFile ./init.nvim;
      };
    };
  in
    nvim
