{ pkgs, ohmytmux }: with pkgs.unstable;
let
  tmuxconfig = stdenv.mkDerivation {
    name = "ohmytmux";
    src = ohmytmux;
    postPatch = ''
      _out=$(echo $out|sed 's/\//\\\//g')
      substituteInPlace .tmux.conf \
        --replace "~/" "$out/" \
        --replace "~\/" "$_out\/"
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
