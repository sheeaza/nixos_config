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
};
in
{
  flake.nixosConfigurations.wsl = inputs.pkgs-stable.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      config.flake.nixosModules.os_cfg1
      config.flake.nixosModules.qm
      local_config
      {
        nixpkgs.overlays = [
          config.flake.overlays.unstable
        ];
      }
      inputs.nixos-wsl.nixosModules.default
    ];
  };
}
