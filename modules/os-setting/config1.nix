# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  internal.nixosModules.os_cfg1 = { pkgs, ... }: {
    documentation.enable = false;

    # Set your time zone.
    time.timeZone = "Asia/Shanghai";

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    # Enable networking
    networking = {
      networkmanager.enable = true;
      useDHCP = false;
      interfaces.ens33.useDHCP = true;
      firewall.enable = false;
    };

    fonts.packages = [ pkgs.nerd-fonts.hack ];
    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      keyMap = "us";
    };

    services.xserver.enable = true;
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;
    # for open vm tools, using x11
    services.displayManager.defaultSession = "plasmax11";
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      plasma-browser-integration
      elisa
      kate
      okular
      gwenview
      kwallet
    ];

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Enable touchpad support (enabled default in most desktopManager).
    services.libinput.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.defaultUserShell = pkgs.unstable.myfish;

    # List packages installed in system profile. To search, run:
    environment.systemPackages = [
      pkgs.unstable.neovim

      pkgs.unstable.tmux

      pkgs.unstable.myfish

      pkgs.wget
      pkgs.tree
      pkgs.ripgrep
      pkgs.tig
      pkgs.git
      pkgs.unstable.fzf

      pkgs.docker-compose
    ];
    environment.sessionVariables.EDITOR = "vim";

    # Enable the OpenSSH daemon.
    services.openssh.enable = true;

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
  };
}
