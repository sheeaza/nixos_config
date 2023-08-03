{
  inputs = {
    upkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05";
    flake-utils.url = github:numtide/flake-utils;

    #neovim
    leaderf-src = {
      url = "github:Yggdroot/LeaderF";
      flake = false;
    };
    clangd-src = {
      url = "https://github.com/clangd/clangd/releases/download/16.0.2/clangd-linux-16.0.2.zip?narHash=sha256-3NSBktpGnSsBSUvGyroFzgNiDWokik1sAliovRYk6tA='";
      flake = false;
    };

    #tmux
    ohmytmux = {
      url = "github:gpakosz/.tmux";
      flake = false;
    };
  };

  outputs = { self, ... }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        overlay-unstable = final: prev: {
          unstable = inputs.upkgs.legacyPackages.${prev.system};
        };
      in let
        pkgs = import inputs.pkgs-stable {
          overlays = [
            overlay-unstable
            ((import ./packages) inputs)
          ];
          inherit system;
        };
      in {
	inherit pkgs;
        packages = {
          dockerImage = import ./docker pkgs;
          cshell = import ./devshell/cshell.nix pkgs;
          rustshell = import ./devshell/rustshell.nix pkgs;
          mynvim = pkgs.mypkg.nvim;
          mytmux = pkgs.mypkg.myfish;
        };
      }
    ) // {
      nixosConfigurations = import ./nixos/configurations inputs;
    };
}
