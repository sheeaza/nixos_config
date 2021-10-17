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
          dockerImage = upkgs.dockerTools.buildImage {
            name = "bundle";
            tag = "latest";
            contents = [ mypkg upkgs.ncurses ];
            config = {
              Cmd = "fish";
	      Env = [
	        "USER=max"
	      ];
              extraCommands = ''
                mkdir /tmp/
              '';
            };
          };
        };
      }
    ) // {
      nixosConfigurations = import ./nixos/configurations inputs;
    };
}
