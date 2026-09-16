let
localfunc = {
  tmux,
  stdenv,
  symlinkJoin,
  makeWrapper,
  ohmytmux,
  bashInteractive,
  replaceVars,
}:
let
  tmuxlocalconf = replaceVars ./tmuxlocal {
  };
in
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
  tmuxconfig = stdenv.mkDerivation {
    name = "ohmytmux";
    src = ohmytmux;
    # mkdir empty plugins to prevent error outputs
    installPhase = ''
      mkdir -p $out/;
      mkdir -p $out/plugins
      sh ${./rewrite-perl.sh} .tmux.conf
      sed -e 's#@bash@#${bashInteractive}/bin/bash#g' -e 's#@blank@#${tmuxBlank}/bin/blank#g' .tmux.conf > $out/.tmux.conf
      cp ${tmuxlocalconf} $out/.tmux.conf.local
    '';
  };
in
let
  _tmux = tmux.override {
    withSystemd = false;
  };
in
let
  wraptmux = symlinkJoin {
    name = "tmux";
    paths = [ _tmux ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/tmux \
      --set TMUX_CONF ${tmuxconfig}/.tmux.conf \
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
