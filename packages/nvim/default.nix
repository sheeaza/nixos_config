{ pkgs, leaderf-src }: with pkgs;
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
in
  let
    nvim = neovim.override {
      withNodeJs = true;
      configure = {
        plug.plugins = with vimPlugins; [
            lightline-vim
            onedark-vim
            nerdcommenter
            (nvim-treesitter.withPlugins (
              plugins: with plugins; [
              tree-sitter-c
              ]
            ))
            coc-nvim
            coc-clangd
            leaderf
            vim-easymotion
        ];
        customRC = builtins.readFile ./init.nvim;
      };
    };
  in
    nvim
