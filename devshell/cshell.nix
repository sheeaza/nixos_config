pkgs:
let
  cshell = pkgs.buildEnv {
    name = "cshell";
    paths = [
      pkgs.gcc
      pkgs.gdb
      pkgs.cmake
      pkgs.gnumake
    ];
  };
in
cshell
