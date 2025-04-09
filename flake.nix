{
  inputs = {
    upkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

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

  outputs =
    {
      self,
      upkgs,
      pkgs-stable,
      clangd-src,
      ohmytmux,
    }:
    let
      system = "x86_64-linux";
    in
    let
      unstable-ov = final: prev: {
        unstable = import upkgs {
          overlays = [
            (final: prev: { inherit clangd-src; })
            (final: prev: { inherit ohmytmux; })
            (import ./packages)
          ];
          inherit system;
        };
      };
    in
    let
      pkgs = import pkgs-stable {
        overlays = [ unstable-ov ];
        inherit system;
      };
    in
    {
      packages."${system}" = {
        dockerImage = import ./docker pkgs;
        dockerimg2 = import ./docker/q.nix pkgs;
        cshell = import ./devshell/cshell.nix pkgs;
        rustshell = import ./devshell/rustshell.nix pkgs;
        mynvim = pkgs.unstable.neovim;
        mytmux = pkgs.unstable.tmux;
        myfish = pkgs.unstable.myfish;
      };
      nixosConfigurations =
        pkgs.lib.genAttrs
          [
            "max"
            "qm"
          ]
          (
            import ./nixos/configurations {
              fpkgs = pkgs-stable;
              inherit system;
              overlays = pkgs.overlays;
            }
          );
    };
}
