{
  tmux,
  stdenv,
  symlinkJoin,
  makeWrapper,
  ohmytmux,
}:
let
  tmuxconfig = stdenv.mkDerivation {
    name = "ohmytmux";
    src = ohmytmux;
    # mkdir empty plugins to prevent error outputs
    installPhase = ''
      mkdir -p $out/;
      mkdir -p $out/plugins
      cp .tmux.conf $out/
      cp ${./tmuxlocal} $out/.tmux.conf.local
    '';
  };
in
let
  wraptmux = symlinkJoin {
    name = "tmux";
    paths = [ tmux ];
    buildInputs = [ makeWrapper ];
    #TMUX_PROGRAM, https://github.com/gpakosz/.tmux/issues/761, could be removed after fixed
    postBuild = ''
      wrapProgram $out/bin/tmux \
      --set TMUX_CONF ${tmuxconfig}/.tmux.conf \
      --set TMUX_PROGRAM ${tmux}/bin/tmux \
      --add-flags "-f ${tmuxconfig}/.tmux.conf"
    '';
  };
in
wraptmux
