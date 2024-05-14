{ fpkgs, system, overlays }:
let
  mkSystem = name: fnixpkgs:
    fnixpkgs.lib.nixosSystem ({
      inherit system;
      modules = [
        ({ config, pkgs, ... }: { nixpkgs.overlays = overlays; })
        {
          networking.hostName = name;
          documentation.enable = false;
        }
        (./. + "/${name}.nix")
        (./. + "/hardware/${name}.nix")
      ];
    });
in { max = mkSystem "max" fpkgs; }
