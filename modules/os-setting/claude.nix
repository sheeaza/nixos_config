{
  internal.nixosModules.claude =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.unstable.cus-claude-code
      ];

      # now unneeded, set in unstable pkg
      # but keep it here, incase later switch to stable one
      nixpkgs.config.allowUnfree = true;
    };
}
