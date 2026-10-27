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
    stableOverlays = lib.mkOption {
      type = lib.types.attrsOf lib.types.raw;
      default = { };
    };
  };
}
