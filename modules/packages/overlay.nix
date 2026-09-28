{ inputs, config, ... }:
let
  unstable_ov = final: prev: {
    unstable = import inputs.upkgs {
      system = final.stdenv.hostPlatform.system;

      overlays = [
        (final: prev: {
         tig = prev.tig.override {
           git = final.gitSlim;
         };}
        )
        config.internal.overlays.git-minimal
        config.internal.overlays.neovim
        config.internal.overlays.openssh-minimal
        config.internal.overlays.fish
        config.internal.overlays.clangd
        config.internal.overlays.tmux
        config.internal.overlays.alacritty
        config.internal.overlays.niri-cfg
      ];
    };
  };
in
{
  internal.overlays.unstable = unstable_ov;
  internal.nixosModules.nixpkgs = {
    nixpkgs.overlays = [ unstable_ov ];
  };
}
