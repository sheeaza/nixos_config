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
  imports = [ ./hardware.nix ];

  documentation.enable = false;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # enable open vm tool
  virtualisation.vmware.guest.enable = true;

  # docker
  virtualisation.docker.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.ens33.useDHCP = true;
  networking.hostName = host;

  fonts.packages = with pkgs; [ (nerdfonts.override { fonts = [ "Hack" ]; }) ];
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    # font = "Hack Nerd Font";
    keyMap = "us";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Plasma 5 Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${host} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "adbusers"
    ]; # Enable ‘sudo’ for the user.
  };
  users.defaultUserShell = pkgs.mypkg.myfish;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = [
    pkgs.mypkg.nvim
    pkgs.mypkg.clangd
    pkgs.universal-ctags

    pkgs.mypkg.tmux
    pkgs.unstable.perl

    pkgs.mypkg.myfish
    pkgs.bashInteractive

    pkgs.wget
    pkgs.tree
    pkgs.ripgrep
    pkgs.tig
    pkgs.git
    pkgs.unstable.fzf

    pkgs.docker-compose

    pkgs.sshfs
  ];
  environment.sessionVariables.EDITOR = "vim";

  programs.adb.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
