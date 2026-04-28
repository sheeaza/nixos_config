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
        config.internal.overlays.neovim
        config.internal.overlays.fish
        config.internal.overlays.clangd
        config.internal.overlays.tmux
        config.internal.overlays.alacritty
        config.internal.overlays.niri-cfg
      ];
    };
  };
  dms-ov = final: prev: {
    dms-shell = final.unstable.dms-shell;
    dgop = final.unstable.dgop;
    quickshell = final.unstable.quickshell;
  };
in
{
  internal.overlays.unstable = unstable_ov;
  internal.nixosModules.nixpkgs = {
    nixpkgs.overlays = [ unstable_ov dms-ov ];
  };
}
