let
  user = "max";
in
{
  internal.overlays.ov_container_devc = final: prev: {
    container_devc = final.dockerTools.buildImage {
      name = "bundle";
      tag = "latest";

      copyToRoot = final.buildEnv {
        name = "image-root";
        paths = [
          (final.buildEnv {
            name = "image-root";
            paths = [
              final.unstable.busybox
              final.unstable.less
              final.unstable.openssh-minimal
              final.unstable.coreutils

              final.unstable.neovim-headless
              final.unstable.tmux
              final.unstable.myfish

              final.unstable.tree
              final.unstable.ripgrep
              final.unstable.tig
              final.unstable.gitSlim
              final.unstable.fzf
            ];
            pathsToLink = [ "/bin" ];
            ignoreCollisions = true;
          })
          (final.buildEnv {
            name = "image-root";
            paths = [ final.unstable.cacert ];
            pathsToLink = [ "/etc/ssl" ];
            ignoreCollisions = true;
          })
          (final.runCommand "user" { } ''
            mkdir -p $out/tmp
            chmod 1777 $out/tmp
            mkdir -p $out/home/${user}/.config/nvim
          '')
          (final.writeTextDir "etc/shadow" ''
            ${user}:!:::::::
          '')
          (final.writeTextDir "etc/passwd" ''
            ${user}:x:0:0::/home/${user}:/bin/fish
          '')
          (final.writeTextDir "etc/group" ''
            ${user}:x:0:
          '')
          (final.writeTextDir "etc/gshadow" ''
            ${user}:x::
          '')
          (final.writeTextDir "etc/gitconfig" ''
            [http]
                sslCAInfo = /etc/ssl/certs/ca-bundle.crt
          '')
        ];
      };
      config = {
        Cmd = [ "fish" ];
        WorkingDir = "/home/${user}";
      };
    };
  };
}
