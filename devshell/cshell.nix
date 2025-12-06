pkgs:
let
  cshell = pkgs.buildEnv {
    name = "cshell";
    paths = [
      pkgs.gcc
      pkgs.gdb
      pkgs.cmake
      pkgs.gnumake
      pkgs.meson
      pkgs.ninja
      pkgs.python3
      pkgs.clang-tools
      pkgs.valgrind
      # pkgs.clang
    ];
  };
in
cshell
