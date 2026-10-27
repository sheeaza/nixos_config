let
localfunc = {
  wrapFish,
  runCommand,
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
  # Ctrl-T's file list comes from rg (see load-env.fish) because fzf's built-in
  # walker ignores .gitignore and would bury a project's real files under build
  # output.
  fzf-env = replaceVars ./load-env.fish {
    rg = "${ripgrep}/bin/rg";
  };

  # fzf's own key bindings are used directly rather than a vendored copy, so
  # they track the fzf package instead of drifting from it.
  #
  # load-env.fish and the fzf bindings must be *sourced at startup*, not
  # autoloaded: vendor_functions.d is lazy and keyed on filename matching the
  # function name, but upstream's file is key-bindings.fish while its function
  # is fzf_key_bindings, so it would never be found. vendor_conf.d is run
  # unconditionally, and the file calls fzf_key_bindings itself at the bottom.
  bundle = runCommand "bundle" { } ''
    functions=$out/share/fish/vendor_functions.d
    conf=$out/share/fish/vendor_conf.d

    install -Dm644 ${fishprompt} $functions/fish_prompt.fish
    install -Dm644 ${./l.fish} $functions/l.fish
    install -Dm644 ${./la.fish} $functions/la.fish
    install -Dm644 ${./ll.fish} $functions/ll.fish
    install -Dm644 ${./lla.fish} $functions/lla.fish
    install -Dm644 ${./git-root.fish} $functions/git-root.fish

    install -Dm644 ${fzf}/share/fzf/key-bindings.fish $conf/key_bindings.fish
    install -Dm644 ${fzf-env} $conf/load-env.fish
  '';

  fishNoMan = fishMinimal.overrideAttrs (old: {
    propagatedBuildInputs = builtins.filter (
      p: (p.pname or "") != "man-db"
    ) old.propagatedBuildInputs;
  });

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

  perSystem = { pkgs, ... }: {
    packages.myfish = pkgs.unstable.myfish;
  };
}
