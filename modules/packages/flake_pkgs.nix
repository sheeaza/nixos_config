{ self, inputs, config, ... }:
{
  perSystem = { system, ... }:
  let
    pkgs = import inputs.pkgs-stable {
      inherit system;
      overlays = [
        config.internal.overlays.unstable
        config.internal.overlays.ov_cshell
        config.internal.overlays.ov_rustshell
        config.internal.overlays.ov_container_devc
        config.internal.overlays.ov_container_devc_q
      ];
    };
  in
  {
    _module.args.pkgs = pkgs;
    packages = {
      dockerImage = pkgs.container_devc;
      dockerimg2 = pkgs.container_devc_q;
      cshell = pkgs.cshell;
      rustshell = pkgs.rustshell;
      mynvim = pkgs.unstable.neovim;
      mytmux = pkgs.unstable.tmux;
      myfish = pkgs.unstable.myfish;
      myalacritty = pkgs.unstable.alacritty;
      myniricfg = pkgs.unstable.niri-cfg;
      wsl_arm64-tarball = config.flake.nixosConfigurations.wsl_arm64.config.system.build.tarballBuilder;
    };
  };
}
