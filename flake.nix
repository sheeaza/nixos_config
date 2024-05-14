{
  inputs = {
    upkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";

    #neovim
    clangd-src = {
      url =
        "https://github.com/clangd/clangd/releases/download/18.1.3/clangd-linux-18.1.3.zip?narHash=sha256-6d1P510uHtXJ8fOyi2OZFyILDS8XgK6vsWFewKFVvq4%3D";
      flake = false;
    };

    #tmux
    ohmytmux = {
      url = "github:gpakosz/.tmux";
      flake = false;
    };
  };

  outputs = { self, upkgs, pkgs-stable, clangd-src, ohmytmux }:
    let
      system = "x86_64-linux";
      unstable-ov = final: prev: {
        unstable = upkgs.legacyPackages.${prev.system};
      };
      mypack-ov = import ./packages { inherit clangd-src ohmytmux; };
    in let
      pkgs = import pkgs-stable {
        overlays = [ unstable-ov mypack-ov ];
        inherit system;
      };
    in {
      packages."${system}" = {
        dockerImage = import ./docker pkgs;
        cshell = import ./devshell/cshell.nix pkgs;
        rustshell = import ./devshell/rustshell.nix pkgs;
        mynvim = pkgs.mypkg.nvim;
        mytmux = pkgs.mypkg.tmux;
      };
      nixosConfigurations = import ./nixos/configurations {
        fpkgs = pkgs-stable;
        inherit system;
        overlays = [ unstable-ov mypack-ov ];
      };
    };
}
