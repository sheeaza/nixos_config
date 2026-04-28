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
  nixpkgs.hostPlatform = "x86_64-linux";
};
in
{
  flake.nixosConfigurations.wsl = inputs.pkgs-stable.lib.nixosSystem {
    modules = [
      config.internal.nixosModules.nixpkgs
      config.internal.nixosModules.os_cfg1
      config.internal.nixosModules.qm
      local_config
      inputs.nixos-wsl.nixosModules.default
    ];
  };
}
