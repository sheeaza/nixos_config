{
  # nanopb_generator imports the `nanopb` Python package, which lives in its
  # own output (passthru.python-module). The stock wrapper never puts it on
  # PYTHONPATH, so the generator fails with "No module named 'nanopb'".
  # Wrap both entrypoints so the module is found without touching the
  # generator's own derivation.
  internal.overlays.nanopb = final: prev: {
    nanopb = final.symlinkJoin {
      name = "nanopb-${prev.nanopb.version}";
      paths = [ prev.nanopb ];
      nativeBuildInputs = [ final.makeWrapper ];
      passthru = prev.nanopb.passthru;
      postBuild = ''
        rm -r $out/bin
        mkdir $out/bin
        for prog in nanopb_generator protoc-gen-nanopb; do
          makeWrapper ${prev.nanopb.generator}/bin/$prog $out/bin/$prog \
            --prefix PYTHONPATH : ${prev.nanopb.python-module}/${final.python3.sitePackages} \
            --prefix PYTHONPATH : ${final.python3.pkgs.protobuf}/${final.python3.sitePackages}
        done
      '';
      meta = prev.nanopb.meta;
    };
  };
}
