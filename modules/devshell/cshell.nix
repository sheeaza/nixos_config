let
  ov_cshell = final: prev: {
    cshell = final.buildEnv {
      name = "cshell";
      paths = [
        # final.gcc
        # final.binutils
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
        final.perf
        final.perfetto
        final.perfetto.tools
      ];
    };
  };
in
{
  internal.stableOverlays.cshell = ov_cshell;

  perSystem = { pkgs, ... }: {
    packages.cshell = pkgs.cshell;
  };
}
