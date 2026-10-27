{ lib, ... }:
{
  options.internal = {
    nixosModules = lib.mkOption {
      type = lib.types.attrsOf lib.types.raw;
      default = { };
    };
    unstableOverlays = lib.mkOption {
      type = lib.types.attrsOf lib.types.raw;
      default = { };
    };
    # Placeholder: nothing registers here yet.
    stableOverlays = lib.mkOption {
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
