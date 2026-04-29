{ ...}:
{
  internal.nixosModules.wsl_niri_dms = { pkgs, lib, ... }: {
    systemd.user.services.dms = {
      # graphical-session.target does not exist on wsl, bind to niri
      after    = [ "niri.service" ];
      bindsTo  = [ "niri.service" ];
      wantedBy = [ "niri.service" ];
      environment = { # need manual set, or qs would not be found
        # need manual set, or qs would not be found, service wont access env path
        PATH = lib.makeBinPath [ pkgs.quickshell ];
        WAYLAND_DISPLAY = "wayland-1"; # niri run on wsl non-session, will deploy wayland 1
      };
    };

    systemd.user.services.niri = {
      serviceConfig = {
        ExecStart = [
          ""
          "${pkgs.unstable.niri}/bin/niri -c ${pkgs.unstable.niri-cfg}"
        ];
      };
      environment = {
         WAYLAND_DISPLAY = "wayland-0"; # on wsl, run as client in wslg
      };
    };
  };
}
