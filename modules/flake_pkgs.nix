{ inputs, config, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.pkgs-stable {
        inherit system;
        overlays = config.internal.pkgOverlays;
      };
    in
    {
      _module.args.pkgs = pkgs;
    };
}
