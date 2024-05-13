{ stdenv, bashInteractive, gcc, autoPatchelfHook, unzip, clangd-src }:
stdenv.mkDerivation {
  name = "clangd";
  src = clangd-src;

  buildInputs = [ bashInteractive gcc ];

  nativeBuildInputs = [ autoPatchelfHook unzip ];

  # sourceRoot = ".";
  installPhase = ''
    mkdir -p $out/bin
    cp $src/bin/clangd $out/bin/
  '';
}
