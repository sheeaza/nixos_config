let
localfunc = {
  alacritty,
  alacritty-theme,
  symlinkJoin,
  makeWrapper,
  stdenv,
  replaceVars,
}:
let
  alac_toml = replaceVars ./alacritty.toml {
    ala-theme = "${alacritty-theme}";
  };
in
let
  alacrittyconfig = stdenv.mkDerivation {
    name = "alacritty_cfg";
    # src = alac_toml;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/;
      cp ${alac_toml} $out/alacritty.toml;
    '';
  };
in
let
  wrap_alacritty = symlinkJoin {
    name = "alacritty";
    paths = [ alacritty ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/alacritty \
      --add-flags "--config-file ${alacrittyconfig}/alacritty.toml"
    '';
  };
in
wrap_alacritty;
in
{
  flake.overlays.alacritty = final: prev: {
    alacritty = final.callPackage localfunc { alacritty = prev.alacritty; };
  };
}
