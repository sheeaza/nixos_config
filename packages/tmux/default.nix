{
  tmux,
  stdenv,
  symlinkJoin,
  makeWrapper,
  ohmytmux,
  perl,
  replaceVars,
}:
let
  tmuxlocalconf = replaceVars ./tmuxlocal {
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
      sed 's#\bperl#${perl}/bin/perl#g' .tmux.conf > $out/.tmux.conf
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
