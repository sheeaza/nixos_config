{
  internal.nixosModules.os_base1 = { lib, pkgs, ... }: {
    documentation.enable = false;

    # Set your time zone.
    time.timeZone = "Asia/Shanghai";

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour. Per-interface DHCP belongs with the
    # hardware module that knows the NIC name (see hw_vm for the VMware guests).
    # Enable networking
    networking = {
      networkmanager.enable = true;
      useDHCP = false;
      firewall.enable = false;
    };

    fonts.packages = [ pkgs.nerd-fonts.hack ];
    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      keyMap = "us";
    };
    # Enable touchpad support (enabled default in most desktopManager).
    services.libinput.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.defaultUserShell = pkgs.unstable.myfish;

    # Enable the OpenSSH daemon.
    services.openssh.enable = true;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.05"; # Did you read the comment?

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Substituters are a lookup chain: Nix asks each in priority order and uses the
      # first one that has the path. A miss or an unreachable mirror simply falls
      # through to the next entry, so the official cache is the automatic fallback
      # and must stay in the list.
      # The explicit ?priority= wins over the Priority field the caches advertise
      # (every one of these reports 40, which would otherwise leave order to chance).
      # mkForce because NixOS otherwise appends this to the default list, which would
      # leave a duplicate cache.nixos.org entry and make the tail order incidental.
      substituters = lib.mkForce [
        "https://mirrors.ustc.edu.cn/nix-channels/store?priority=10"
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=20"
        "https://cache.nixos.org?priority=40"
      ];

      # The mirrors proxy cache.nixos.org and serve its upstream signatures, so the
      # default trusted key already covers them -- no extra key needed here.

      # Don't let a dead mirror stall the whole build; fail fast and move down the chain.
      connect-timeout = 5;
      # A mirror that lags upstream shouldn't have its misses remembered for an hour.
      narinfo-cache-negative-ttl = 60;
      # Substituters are best-effort: if all of them miss, build from source.
      fallback = true;
    };
  };
}
