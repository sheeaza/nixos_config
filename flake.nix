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
        mypkg = import ./packages inputs;
      in {
        defaultPackage = mypkg;
        packages = {
          dockerImage = upkgs.dockerTools.buildLayeredImage {
            name = "bundle image";
            contents = [ upkgs.fish upkgs.coreutils upkgs.gnutar upkgs.tree ];
            config = {
              Cmd = "fish";
            };
          };
        };
	inherit mypkg;
      }
    ) // {
      nixosConfigurations = import ./nixos/configurations inputs;
    };
}
