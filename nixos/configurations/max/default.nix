# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  host,
  ...
}:
{
  imports = [
    ./hardware.nix
    ../common/boot.nix
    ../common/config1.nix
  ];

  # enable open vm tool
  virtualisation.vmware.guest.enable = true;

  # docker
  virtualisation.docker.enable = true;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = [
    pkgs.unstable.lua-language-server
  ];
  services.vscode-server.enable = true;
  systemd.user.services.auto-fix-vscode-server = {
      enable = true;
  };
}
