{ tmux, stdenv, symlinkJoin, makeWrapper, ohmytmux }:
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
in let
  wraptmux = symlinkJoin {
    name = "tmux";
    paths = [ tmux ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/tmux \
      --set TMUX_CONF ${tmuxconfig}/.tmux.conf \
      --add-flags "-f ${tmuxconfig}/.tmux.conf"
    '';
  };
in wraptmux
