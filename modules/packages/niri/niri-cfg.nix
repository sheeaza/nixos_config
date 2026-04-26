let
localfunc = {
  symlinkJoin,
  makeWrapper,
  stdenv,
  alacritty,
  substitute,
}:
let
  niri-kdl = substitute {
    name = "niri-kdl";
    src = ./config.kdl;
    substitutions = [
      "--replace-fail"
      "@alacritty@"
      "${alacritty}/bin/alacritty"
    ];
  };
in
let
  niri-config = stdenv.mkDerivation {
    name = "nifi_cfg";
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/;
      cp ${niri-kdl} $out/config.kdl;
    '';
  };
in
niri-kdl;
in
{
  flake.overlays.niri-cfg = final: prev: {
    niri-cfg = final.callPackage localfunc {};
  };
}
