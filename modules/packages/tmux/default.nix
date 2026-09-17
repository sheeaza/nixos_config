let
localfunc = {
  tmux,
  stdenv,
  symlinkJoin,
  makeWrapper,
  bashInteractive,
}:
let
  tmuxBlank = stdenv.mkDerivation {
    name = "tmux-blank";
    dontUnpack = true;
    buildPhase = ''
      $CC -O2 -Wall -o blank ${./blank.c}
    '';
    installPhase = ''
      mkdir -p $out/bin
      cp blank $out/bin/blank
    '';
  };
in
let
  _tmux = tmux.override {
    withSystemd = false;
  };
in
let
  tmuxconfig = stdenv.mkDerivation {
    name = "ohmytmux";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out
      sedArgs=(
        -e 's#@bash@#${bashInteractive}/bin/bash#g'
        -e 's#@blank@#${tmuxBlank}/bin/blank#g'
        -e 's#@sh@#'"$out"'/tmux.sh#g'
        -e 's#@tmux_conf@#'"$out"'/.tmux.conf#g'
        -e 's#@tmux_program@#${_tmux}/bin/tmux#g'
      )
      sed "''${sedArgs[@]}" ${./tmuxconf} > $out/.tmux.conf
      sed "''${sedArgs[@]}" ${./tmuxconf.sh} > $out/tmux.sh
      chmod +x $out/tmux.sh
    '';
  };
in
let
  wraptmux = symlinkJoin {
    name = "tmux";
    paths = [ _tmux ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/tmux \
      --add-flags "-f ${tmuxconfig}/.tmux.conf" \
      --set-default LANG C.UTF-8 \
      --set-default LC_ALL C.UTF-8
    '';
  };
in
wraptmux;
in
{
  internal.overlays.tmux = final: prev: {
    tmux = final.callPackage localfunc { tmux = prev.tmux; };
  };
}
