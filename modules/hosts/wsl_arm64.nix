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

  nixpkgs.buildPlatform = "x86_64-linux";
  nixpkgs.hostPlatform = "aarch64-linux";
};
in
{
  flake.nixosConfigurations.wsl_arm64 = inputs.pkgs-stable.lib.nixosSystem {
    modules = [
      config.flake.nixosModules.nixpkgs
      config.flake.nixosModules.os_cfg1
      config.flake.nixosModules.qm
      local_config
      inputs.nixos-wsl.nixosModules.default
    ];
  };
}
