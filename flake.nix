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
        upkgs = inputs.upkgs.legacyPackages.${system};
        pkgs = inputs.pkgs-2105.legacyPackages.${system};
        mypkg = import ./packages inputs;
      in {
        defaultPackage = mypkg;
        packages = {
          dockerImage = import ./docker {
	    pkgs = pkgs;
	    upkgs = upkgs;
	    bundle = mypkg;
	  };
        };
      }
    ) // {
      nixosConfigurations = import ./nixos/configurations inputs;
    };
}
