{
  internal.unstableOverlays.cus-tmux =
    final: _prev:
    let
      _tmux = final.tmux.override {
        withSystemd = false;
      };
      tmuxconfig = final.stdenv.mkDerivation {
        name = "ohmytmux";
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out
          sedArgs=(
            -e 's#@bash@#${final.bashInteractive}/bin/bash#g'
            -e 's#@sh@#'"$out"'/tmux.sh#g'
            -e 's#@tmux_conf@#'"$out"'/.tmux.conf#g'
            -e 's#@tmux_program@#${_tmux}/bin/tmux#g'
          )
          sed "''${sedArgs[@]}" ${./tmuxconf} > $out/.tmux.conf
          sed "''${sedArgs[@]}" ${./tmuxconf.sh} > $out/tmux.sh
          chmod +x $out/tmux.sh
        '';
      };
      wraptmux = final.symlinkJoin {
        name = "tmux";
        paths = [ _tmux ];
        buildInputs = [ final.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/tmux \
          --add-flags "-f ${tmuxconfig}/.tmux.conf" \
          --set-default LANG C.UTF-8 \
          --set-default LC_ALL C.UTF-8
        '';
      };
    in
    {
      cus-tmux = wraptmux;
    };

  perSystem = { pkgs, ... }: {
    packages.mytmux = pkgs.unstable.cus-tmux;
  };
}
