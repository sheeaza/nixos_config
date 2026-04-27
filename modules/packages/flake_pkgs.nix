{ self, inputs, config, ... }:
{
  perSystem = { system, ... }:
  let
    pkgs = import inputs.pkgs-stable {
      inherit system;
      overlays = [
        self.overlays.unstable
        self.overlays.ov_cshell
        self.overlays.ov_rustshell
        self.overlays.ov_container_devc
        self.overlays.ov_container_devc_q
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
