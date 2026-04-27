# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  inputs,
  ...
}:
let local_config = { pkgs, ... }: {
  # enable open vm tool
  virtualisation.vmware.guest.enable = true;

  # docker
  virtualisation.docker.enable = true;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = [
    pkgs.bashInteractive
    pkgs.sshfs
  ];

  programs.adb.enable = true;

  networking = {
    hostName = "vm";
  };

  nixpkgs.hostPlatform = "x86_64-linux";
};
in
{
  flake.nixosConfigurations.vm_qm = inputs.pkgs-stable.lib.nixosSystem {
    modules = [
      config.flake.nixosModules.nixpkgs
      config.flake.modules.nixos.boot
      config.flake.nixosModules.vm_hw
      config.flake.nixosModules.os_cfg1
      config.flake.nixosModules.qm
      local_config
    ];
  };
}
