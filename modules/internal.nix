{ lib, ... }:
{
  options.internal = {
    nixosModules = lib.mkOption {
      type = lib.types.attrsOf lib.types.raw;
      default = {};
    };
    overlays = lib.mkOption {
      type = lib.types.attrsOf lib.types.raw;
      default = {};
    };
  };
}
