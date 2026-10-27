{
  inputs,
  config,
  lib,
  ...
}:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.pkgs-stable {
        inherit system;
        overlays = config.internal.pkgOverlays ++ lib.attrValues config.internal.stableOverlays;
      };
    in
    {
      _module.args.pkgs = pkgs;
    };
}
