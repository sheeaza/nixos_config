{ ...}:
{
  internal.nixosModules.sddm_niri = { pkgs, ... }:
    let
      custom-sddm-astronaut = pkgs.sddm-astronaut.override {
        embeddedTheme = "astronaut";
      };
    in {
      services.displayManager.sddm = {
        enable = true;
        wayland = {
          enable = true;
          compositor = "weston";
        };
        enableHidpi = true;
        theme = "sddm-astronaut-theme";
        settings = {
          Theme = {
            Current = "sddm-astronaut-theme";
            CursorTheme = "Bibata-Modern-Ice";
            CursorSize = 20;
          };
        };
        extraPackages = with pkgs; [
          custom-sddm-astronaut
        ];
      };

      environment.systemPackages = [
        custom-sddm-astronaut
        pkgs.bibata-cursors
      ];
    };
}
