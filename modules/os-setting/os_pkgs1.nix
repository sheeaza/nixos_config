{
  internal.nixosModules.os_pkgs1 = { pkgs, ... }: {
    # List packages installed in system profile. To search, run:
    environment.systemPackages = [
      pkgs.unstable.neovim

      pkgs.unstable.tmux

      pkgs.unstable.myfish

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
