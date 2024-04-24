{
  inputs = {
    upkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = github:numtide/flake-utils;

    #neovim
    clangd-src = {
      url = "https://github.com/clangd/clangd/releases/download/18.1.3/clangd-linux-18.1.3.zip?narHash=sha256-6d1P510uHtXJ8fOyi2OZFyILDS8XgK6vsWFewKFVvq4%3D";
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
          mytmux = pkgs.mypkg.tmux;
        };
      }
    ) // {
      nixosConfigurations = import ./nixos/configurations inputs;
    };
}
