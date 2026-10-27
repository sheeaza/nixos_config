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
        overlays = lib.attrValues config.internal.stableOverlays;
      };
    in
    {
      _module.args.pkgs = pkgs;
    };
}
