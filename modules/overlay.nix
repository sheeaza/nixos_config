{
  inputs,
  config,
  lib,
  ...
}:
let
  unstable_ov = final: prev: {
    unstable = import inputs.upkgs {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;

      overlays = lib.attrValues config.internal.unstableOverlays;
    };
  };
in
{
  internal.stableOverlays.unstable = unstable_ov;
  internal.nixosModules.nixpkgs = {
    nixpkgs.overlays = lib.attrValues config.internal.stableOverlays;
  };
}
