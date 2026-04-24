{ inputs, config, ... }:
{
  flake.overlays = {
    unstable = final: prev: {
      unstable = import inputs.upkgs {
        system = final.system;

        overlays = [
          (final: prev: { clangd-src = inputs.clangd-src; })
          (final: prev: { ohmytmux = inputs.ohmytmux; })
          (final: prev: {
           tig = prev.tig.override {
             git = final.gitMinimal;
           };}
          )
          config.flake.overlays.neovim
          config.flake.overlays.fish
          config.flake.overlays.clangd
          config.flake.overlays.tmux
        ];
      };
    };
  };
}
