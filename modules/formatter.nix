{
  perSystem =
    { pkgs, ... }:
    {
      # `nix fmt` formats the whole tree; checks/checks.nix verifies it.
      formatter = pkgs.nixfmt-tree;
    };
}
