{
  fpkgs,
  system,
  overlays,
}:
user:
fpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    (
      { config, pkgs, ... }:
      {
        nixpkgs.overlays = overlays;
      }
    )
    { _module.args.host = user; }
    (./. + "/${user}/default.nix")
  ];
}
