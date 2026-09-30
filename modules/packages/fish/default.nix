let
localfunc = {
  wrapFish,
  stdenv,
  busybox,
  substitute,
  fishMinimal,
  fzf,
  replaceVars,
  ripgrep,
}:
let
  fishprompt = substitute {
    name = "fish_prompt.fish";
    src = ./fish_prompt.fish;
    substitutions = [
      "--replace-fail"
      " sed "
      " ${busybox}/bin/sed "
    ];
  };
  # Use fzf's own key bindings rather than a vendored copy, so they track the
  # fzf package instead of drifting from it. Ctrl-T's file list still comes from
  # rg (see load-env.fish) because fzf's built-in walker ignores .gitignore and
  # would bury a project's real files under build output.
  fzf-key = substitute {
    name = "key_bindings.fish";
    src = "${fzf}/share/fzf/key-bindings.fish";
    substitutions = [ ];
  };
  fzf-env = replaceVars ./load-env.fish {
    rg = "${ripgrep}/bin/rg";
  };
in
let
  bundle = stdenv.mkDerivation {
    name = "bundle";
    phases = [ "installPhase" ];
    src = [
      "${fishprompt}"
      "${fzf-key}"
      ./l.fish
      ./la.fish
      ./ll.fish
      ./lla.fish
      ./git-root.fish
      "${fzf-env}"
    ];
    installPhase = ''
      mkdir -p $out/share/fish/vendor_functions.d
      for srcFile in $src; do
        local tgt=$(echo $srcFile | cut --delimiter=- --fields=2-)
        cp $srcFile $out/share/fish/vendor_functions.d/$tgt
      done

      mkdir -p $out/share/fish/vendor_conf.d
      # load-env.fish and the fzf bindings must be *sourced at startup*, not
      # autoloaded: vendor_functions.d is lazy and keyed on filename matching the
      # function name, but upstream's file is key-bindings.fish while its function
      # is fzf_key_bindings, so it would never be found. vendor_conf.d is run
      # unconditionally, and the file calls fzf_key_bindings itself at the bottom.
      mv $out/share/fish/vendor_functions.d/load-env.fish $out/share/fish/vendor_conf.d/load-env.fish
      mv $out/share/fish/vendor_functions.d/key_bindings.fish $out/share/fish/vendor_conf.d/key_bindings.fish
    '';
  };
in
let
  fishNoMan = fishMinimal.overrideAttrs (old: {
    propagatedBuildInputs = builtins.filter (
      p: (p.pname or "") != "man-db"
    ) old.propagatedBuildInputs;
  });
in
let
_wrapFish = wrapFish.override {
  fish = fishNoMan;
};
in
(_wrapFish {
  pluginPkgs = [
    bundle
  ];
}).overrideAttrs
  (_: {
    passthru.shellPath = "/bin/fish";
  });
in
{
  internal.overlays.fish = final: prev: {
    myfish = final.callPackage localfunc {};
  };
}
