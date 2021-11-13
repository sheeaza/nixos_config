{
  inputs = {
    upkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pkgs-2105.url = "github:nixos/nixpkgs/nixos-21.05";
    flake-utils.url = github:numtide/flake-utils;

    #neovim
    leaderf-src = {
      url = "github:Yggdroot/LeaderF";
      flake = false;
    };
    clangd-src = {
      url = "https://github.com/clangd/clangd/releases/download/13.0.0/clangd-linux-13.0.0.zip";
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
        pkgs = import inputs.pkgs-2105 {
          overlays = [
            overlay-unstable
            ((import ./packages) inputs)
          ];
          inherit system;
        };
      in {
	inherit pkgs;
        defaultPackage = pkgs.mypkg;
        packages = {
          dockerImage = import ./docker pkgs;
        };
      }
    ) // {
      nixosConfigurations = import ./nixos/configurations inputs;
    };
}
