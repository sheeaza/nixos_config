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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${host} = {
    extraGroups = [
      "adbusers"
    ]; # Enable ‘sudo’ for the user.
  };
  users.defaultUserShell = pkgs.unstable.myfish;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = [
    pkgs.unstable.neovim
    pkgs.bashInteractive
    pkgs.sshfs
  ];
  programs.adb.enable = true;

}
