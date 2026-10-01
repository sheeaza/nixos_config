# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  inputs,
  ...
}:
let local_config = { ... }: {
  nixpkgs.hostPlatform = "x86_64-linux";
};
in
{
  flake.nixosConfigurations.wsl_headless = inputs.pkgs-stable.lib.nixosSystem {
    modules = [
      config.internal.nixosModules.nixpkgs
      config.internal.nixosModules.wsl_common
      config.internal.nixosModules.os_base1
      config.internal.nixosModules.os_pkgs1
      config.internal.nixosModules.nixos
      config.internal.nixosModules.os_docker
      config.internal.nixosModules.claude
      config.internal.nixosModules.vs-code
      local_config
    ];
  };
}
