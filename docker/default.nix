pkgs: with pkgs;
let
  user = "max";
in
  pkgs.dockerTools.buildImage {
    name = "bundle";
    tag = "latest";

    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      paths = [
        (
          pkgs.buildEnv {
            name = "image-root";
            paths = [
              pkgs.unstable.busybox
              pkgs.unstable.less
              pkgs.unstable.ncurses
              pkgs.unstable.openssh
              pkgs.unstable.coreutils
              pkgs.unstable.findutils
              pkgs.unstable.gnutar
              pkgs.unstable.bash

              pkgs.mypkg.nvim
              pkgs.mypkg.clangd
              pkgs.unstable.global
              pkgs.unstable.universal-ctags

              pkgs.mypkg.tmux
              pkgs.unstable.perl

              pkgs.mypkg.myfish

              pkgs.unstable.wget
              pkgs.unstable.tree
              pkgs.unstable.ripgrep
              pkgs.unstable.tig
              pkgs.unstable.git
              pkgs.unstable.fzf
            ];
            pathsToLink = [ "/bin" ];
            ignoreCollisions = true;
          }
        ) (
          pkgs.runCommand "user" { } ''
            mkdir -p $out/tmp
            chmod 1777 $out/tmp
            mkdir -p $out/home/${user}/.config/nvim
            ln -s ${./../packages/nvim/coc-settings.json} $out/home/${user}/.config/nvim/coc-settings.json
          ''
        ) (
          writeTextDir "etc/shadow" ''
            ${user}:!:::::::
          ''
        ) (
          writeTextDir "etc/passwd" ''
            ${user}:x:0:0::/home/${user}:/bin/fish
          ''
        ) (
          writeTextDir "etc/group" ''
            ${user}:x:0:
          ''
        ) (
          writeTextDir "etc/gshadow" ''
            ${user}:x::
          ''
        )
      ];
    };
    config = {
      Cmd = "fish";
      WorkingDir = "/home/${user}";
      Env = [
      ];
    };
  }
