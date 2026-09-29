{
  internal.nixosModules.claude = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.claude-code
    ];

    # claude-code is unfree; keep that fact with the package rather than
    # relying on every host that imports this to have set it already.
    nixpkgs.config.allowUnfree = true;
  };
}
