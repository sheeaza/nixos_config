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
      unstable-ov = final: prev: { unstable = upkgs.legacyPackages.${prev.system}; };
      clangd-src-ov = final: prev: { inherit clangd-src; };
      ohmytmux-ov = final: prev: { inherit ohmytmux; };
      mypack-ov = import ./packages;
    in
    let
      pkg-ov = [
        unstable-ov
        clangd-src-ov
        ohmytmux-ov
        mypack-ov
      ];
    in
    let
      pkgs = import pkgs-stable {
        overlays = pkg-ov;
        inherit system;
      };
    in
    {
      packages."${system}" = {
        dockerImage = import ./docker pkgs;
        dockerimg2 = import ./docker/q.nix pkgs;
        cshell = import ./devshell/cshell.nix pkgs;
        rustshell = import ./devshell/rustshell.nix pkgs;
        mynvim = pkgs.mypkg.nvim;
        mytmux = pkgs.mypkg.tmux;
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
              overlays = pkg-ov;
            }
          );
    };
}
