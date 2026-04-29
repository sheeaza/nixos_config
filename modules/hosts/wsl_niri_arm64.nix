# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  inputs,
  ...
}:
let local_config = { pkgs, ... }: {

  wsl.enable = true;
  # List packages installed in system profile. To search, run:
  environment.systemPackages = [
    pkgs.bashInteractive
    pkgs.sshfs
    pkgs.xclip
  ];

  networking = {
    hostName = "wsl";
  };

  nixpkgs.hostPlatform = "aarch64-linux";
};
in
{
  flake.nixosConfigurations.wsl_niri_arm64 = inputs.pkgs-stable.lib.nixosSystem {
    modules = [
      config.internal.nixosModules.nixpkgs
      config.internal.nixosModules.os_niri
      config.internal.nixosModules.nixos
      config.internal.nixosModules.wsl_niri_dms
      config.internal.nixosModules.os_base1
      config.internal.nixosModules.os_pkgs1
      inputs.nixos-wsl.nixosModules.default
      local_config
    ];
  };
}
