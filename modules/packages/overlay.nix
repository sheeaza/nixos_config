{ inputs, config, ... }:
let
  unstable_ov = final: prev: {
    unstable = import inputs.upkgs {
      system = final.stdenv.hostPlatform.system;

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
        config.flake.overlays.alacritty
        config.flake.overlays.niri-cfg
      ];
    };
  };
  dms-ov = final: prev: {
    dms-shell = final.unstable.dms-shell;
    dgop = final.unstable.dgop;
  };
in
{
  flake.overlays.unstable = unstable_ov;
  flake.nixosModules.nixpkgs = {
    nixpkgs.overlays = [ unstable_ov dms-ov ];
  };
}
