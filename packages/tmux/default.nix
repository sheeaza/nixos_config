{
  tmux,
  stdenv,
  symlinkJoin,
  makeWrapper,
  ohmytmux,
  perl,
  substituteAll,
}:
let
  tmuxlocalconf = substituteAll {
    src = ./tmuxlocal;
    perl = "${perl}";
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
      cp .tmux.conf $out/
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
      --add-flags "-f ${tmuxconfig}/.tmux.conf"
    '';
  };
in
wraptmux
