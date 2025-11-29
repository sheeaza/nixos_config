{
  fpkgs,
  system,
  overlays,
  vsc-server,
}:
user:
fpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    vsc-server.nixosModules.default
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
