{
  internal.unstableOverlays.niri-cfg =
    final: _prev:
    let
      niri-kdl = final.substitute {
        name = "niri-kdl";
        src = ./config.kdl;
        substitutions = [
          "--replace-fail"
          "@alacritty@"
          "${final.cus-alacritty}/bin/alacritty"
        ];
      };
    in
    {
      niri-cfg = niri-kdl;
    };

  perSystem = { pkgs, ... }: {
    packages.myniricfg = pkgs.unstable.niri-cfg;
  };
}
