{ inputs, ...}:
{
  internal.nixosModules.os_niri = { pkgs, lib, ... }: {
    programs.niri = {
      enable = true;
    };
    systemd.user.services.niri = {
      serviceConfig = {
        ExecStart = [
          ""
          "${pkgs.niri}/bin/niri --session -c ${pkgs.unstable.niri-cfg}"
        ];
      };
      path = lib.mkForce [ ];
    };

    programs.dms-shell = {
      enable = true;
      enableSystemMonitoring = true;
    };
    services.displayManager.dms-greeter = {
      enable = true;
      compositor = {
        name = "niri";
        customConfig = ''
          cursor {
            xcursor-theme "Bibata-Modern-Ice"
            xcursor-size 20
          }
          hotkey-overlay {
              skip-at-startup
          }
        '';
      };
    };

    environment.systemPackages = [
      pkgs.xwayland-satellite
      pkgs.unstable.alacritty
      pkgs.bibata-cursors
    ];
  };
}
