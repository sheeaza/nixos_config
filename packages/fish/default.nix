{ wrapFish, stdenv, fzf }:
let
  bundle = stdenv.mkDerivation {
    name = "bundle";
    phases = [ "installPhase" ];
    src = [
      ./fish_prompt.fish
      ./l.fish
      ./la.fish
      ./ll.fish
      ./lla.fish
      ./git-root.fish
      ./load-env.fish
    ];
    installPhase = ''
      mkdir -p $out/share/fish/vendor_functions.d
      for srcFile in $src; do
        local tgt=$(echo $srcFile | cut --delimiter=- --fields=2-)
        cp $srcFile $out/share/fish/vendor_functions.d/$tgt
      done

      mkdir -p $out/share/fish/vendor_conf.d
      mv $out/share/fish/vendor_functions.d/load-env.fish $out/share/fish/vendor_conf.d/load-env.fish
    '';
  };
in
  (wrapFish {
    pluginPkgs = [ fzf bundle ];
  }).overrideAttrs (_: {
    passthru.shellPath = "/bin/fish";
  })
