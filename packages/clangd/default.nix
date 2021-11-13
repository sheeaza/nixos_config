{ pkgs, clangd-src }: with pkgs.unstable;
let
in
  stdenv.mkDerivation {
    name = "clangd";
    src = clangd-src;
  
    buildInputs = [
      bashInteractive
      gcc
    ];
  
    nativeBuildInputs = [
      autoPatchelfHook
      unzip
    ];
  
    # sourceRoot = ".";
    installPhase = ''
      mkdir -p $out/bin
      cp $src/bin/clangd $out/bin/
    '';
  }
