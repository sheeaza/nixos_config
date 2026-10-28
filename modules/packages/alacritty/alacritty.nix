{
  internal.unstableOverlays.cus-alacritty =
    final: _prev:
    let
      alac_toml = final.replaceVars ./alacritty.toml {
        ala-theme = "${final.alacritty-theme}";
      };
      alacrittyconfig = final.stdenv.mkDerivation {
        name = "alacritty_cfg";
        phases = [ "installPhase" ];
        installPhase = ''
          mkdir -p $out/;
          cp ${alac_toml} $out/alacritty.toml;
        '';
      };
      wrap_alacritty = final.symlinkJoin {
        name = "alacritty";
        paths = [ final.alacritty ];
        buildInputs = [ final.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/alacritty \
          --add-flags "--config-file ${alacrittyconfig}/alacritty.toml"
        '';
      };
    in
    {
      cus-alacritty = wrap_alacritty;
    };

  perSystem = { pkgs, ... }: {
    packages.myalacritty = pkgs.unstable.cus-alacritty;
  };
}
