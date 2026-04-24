{
  flake.overlays.ov_cshell = final: prev: {
    cshell = final.buildEnv {
      name = "cshell";
      paths = [
        # pkgs.gcc
        final.gdb
        final.cmake
        final.gnumake
        final.meson
        final.ninja
        final.python3
        final.clang-tools
        final.valgrind
        final.clang
      ];
    };
  };
}
