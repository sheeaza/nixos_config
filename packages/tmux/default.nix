{ pkgs, ohmytmux }: with pkgs.unstable;
let
  tmuxconfig = stdenv.mkDerivation {
    name = "ohmytmux";
    src = ohmytmux;
    installPhase = ''
      mkdir -p $out/;
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
      postBuild = ''
      wrapProgram $out/bin/tmux \
      --set TMUX_CONF ${tmuxconfig}/.tmux.conf \
      --add-flags "-f ${tmuxconfig}/.tmux.conf"
      '';
    };
  in
    wraptmux
