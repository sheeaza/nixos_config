{
  fpkgs,
  system,
  overlays,
  vsc-server,
  nixos-wsl,
}:
user:
fpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    vsc-server.nixosModules.default
    nixos-wsl.nixosModules.default
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
