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
niri-kdl;
in
{
  flake.overlays.niri-cfg = final: prev: {
    niri-cfg = final.callPackage localfunc {};
  };
}
