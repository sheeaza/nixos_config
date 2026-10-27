let
  mkDevcImage =
    { pkgs, user, extraPaths ? [ ] }:
    pkgs.dockerTools.buildImage {
      name = "bundle";
      tag = "latest";

      copyToRoot = pkgs.buildEnv {
        name = "image-root";
        paths = [
          (pkgs.buildEnv {
            name = "image-root";
            paths = [
              pkgs.unstable.busybox
              pkgs.unstable.less
              pkgs.unstable.openssh-minimal
              pkgs.unstable.coreutils

              pkgs.unstable.neovim-headless
              pkgs.unstable.tmux
              pkgs.unstable.myfish

              pkgs.unstable.tree
              pkgs.unstable.ripgrep
              pkgs.unstable.tig
              pkgs.unstable.gitSlim
              pkgs.unstable.fzf
            ];
            pathsToLink = [ "/bin" ];
            ignoreCollisions = true;
          })
          (pkgs.buildEnv {
            name = "image-root";
            paths = [ pkgs.unstable.cacert ];
            pathsToLink = [ "/etc/ssl" ];
            ignoreCollisions = true;
          })
          (pkgs.runCommand "user" { } ''
            mkdir -p $out/tmp
            chmod 1777 $out/tmp
            mkdir -p $out/home/${user}/.config/nvim
          '')
          (pkgs.writeTextDir "etc/shadow" ''
            ${user}:!:::::::
          '')
          (pkgs.writeTextDir "etc/passwd" ''
            ${user}:x:0:0::/home/${user}:/bin/fish
          '')
          (pkgs.writeTextDir "etc/group" ''
            ${user}:x:0:
          '')
          (pkgs.writeTextDir "etc/gshadow" ''
            ${user}:x::
          '')
          (pkgs.writeTextDir "etc/gitconfig" ''
            [http]
                sslCAInfo = /etc/ssl/certs/ca-bundle.crt
          '')
        ] ++ extraPaths;
      };
      config = {
        Cmd = [ "fish" ];
        WorkingDir = "/home/${user}";
      };
    };

  ov_container_devc = final: prev: {
    container_devc = mkDevcImage { pkgs = final; user = "max"; };
  };

  ov_container_devc_q = final: prev: {
    container_devc_q = mkDevcImage {
      pkgs = final;
      user = "qm";
      extraPaths = [
        (final.runCommand "workspace-dir" { } ''
          mkdir -p $out/local/mnt/workspace
        '')
      ];
    };
  };
in
{
  internal.pkgOverlays = [
    ov_container_devc
    ov_container_devc_q
  ];

  perSystem = { pkgs, ... }: {
    packages = {
      dockerImage = pkgs.container_devc;
      dockerimg2 = pkgs.container_devc_q;
    };
  };
}
