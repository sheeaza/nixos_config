{
  internal.nixosModules.os_pkgs = { pkgs, ... }: {
    # List packages installed in system profile. To search, run:
    environment.systemPackages = [
      pkgs.nix-tree
      pkgs.wget
      pkgs.tree
      pkgs.ripgrep
      pkgs.tig
      pkgs.git
      pkgs.unstable.fzf
      pkgs.unzip
    ];
    environment.sessionVariables.EDITOR = "vim";
  };
}
