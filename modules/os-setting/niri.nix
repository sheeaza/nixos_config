{ inputs, ...}:
{
  internal.nixosModules.os_niri = { pkgs, lib, ... }: {
    imports = [
      { disabledModules = [ "programs/wayland/niri.nix" ]; }
      "${inputs.upkgs}/nixos/modules/programs/wayland/niri.nix"

      "${inputs.upkgs}/nixos/modules/programs/wayland/dms-shell.nix"
      "${inputs.upkgs}/nixos/modules/services/display-managers/dms-greeter.nix"
    ];
    programs.niri = {
      enable = true;
    };
    systemd.user.services.niri = {
      serviceConfig = {
        ExecStart = [
          ""
          "${pkgs.unstable.niri}/bin/niri --session -c ${pkgs.unstable.niri-cfg}"
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
