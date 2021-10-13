{ pkgs, ohmytmux }: with pkgs;
let
  tmuxconfig = stdenv.mkDerivation {
    name = "ohmytmux";
    src = ohmytmux;
      #for file in .tmux.conf; do
    postPatch = ''
        substituteInPlace .tmux.conf \
          --replace "~/" "$out/" \
          --replace "~\/" "$out\/"
    '';
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
      --add-flags "-f ${tmuxconfig}/.tmux.conf"
      '';
    };
  in
    wraptmux
