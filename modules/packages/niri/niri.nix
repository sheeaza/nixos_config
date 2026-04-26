let
localfunc = {
  symlinkJoin,
  makeWrapper,
  stdenv,
  niri,
  alacritty,
  substitute,
  nix-update-script,
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
let
  wrap_niri = symlinkJoin {
    name = "niri";
    paths = [ niri ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/niri \
      --add-flags "-c ${niri-config}/config.kdl"
    '';
    passthru = {
      providedSessions = [ "niri" ];
      updateScript = nix-update-script { };
    };
  };
in
wrap_niri;
in
{
  flake.overlays.niri = final: prev: {
    niri = final.callPackage localfunc { niri = prev.niri; };
  };
}
