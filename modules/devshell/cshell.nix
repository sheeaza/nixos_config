{
  internal.overlays.ov_cshell = final: prev: {
    cshell = final.buildEnv {
      name = "cshell";
      paths = [
        # final.gcc
        final.gdb
        final.cmake
        final.gnumake
        final.meson
        final.ninja
        final.python3_cdev
        final.valgrind
        final.clang
        final.pre-commit
        final.clang-tools
        final.linuxPackages.perf
      ];
    };
  };
}
