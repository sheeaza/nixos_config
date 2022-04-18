{
  inputs = {
    upkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pkgs-stable.url = "github:nixos/nixpkgs/nixos-21.11";
    flake-utils.url = github:numtide/flake-utils;

    #neovim
    leaderf-src = {
      url = "github:Yggdroot/LeaderF";
      flake = false;
    };
    clangd-src = {
      url = "https://github.com/clangd/clangd/releases/download/14.0.0/clangd-linux-14.0.0.zip";
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
        };
      }
    ) // {
      nixosConfigurations = import ./nixos/configurations inputs;
    };
}
