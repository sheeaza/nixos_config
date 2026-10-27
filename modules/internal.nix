{ lib, ... }:
{
  options.internal = {
    nixosModules = lib.mkOption {
      type = lib.types.attrsOf lib.types.raw;
      default = { };
    };
    overlays = lib.mkOption {
      type = lib.types.attrsOf lib.types.raw;
      default = { };
    };
    # Overlays each module wants applied to the flake's package set.
    pkgOverlays = lib.mkOption {
      type = lib.types.listOf lib.types.raw;
      default = [ ];
    };
  };
}
