let
  user = "qm";
in
{
  internal.overlays.ov_container_devc_q = final: prev: {
    container_devc_q = final.dockerTools.buildImage {
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
              final.unstable.openssh
              final.unstable.coreutils

              final.unstable.neovim
              final.unstable.tmux
              final.unstable.myfish

              final.unstable.tree
              final.unstable.ripgrep
              final.unstable.tig
              final.unstable.gitMinimal
              final.unstable.fzf
            ];
            pathsToLink = [ "/bin" ];
            ignoreCollisions = true;
          })
          (final.runCommand "user" { } ''
            mkdir -p $out/tmp
            chmod 1777 $out/tmp
            mkdir -p $out/home/${user}/.config/nvim

            mkdir -p $out/local/mnt/workspace
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
        ];
      };
      config = {
        Cmd = "fish";
        WorkingDir = "/home/${user}";
      };
    };
  };
}
