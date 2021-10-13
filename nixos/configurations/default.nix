{ self, ... }@inputs:
let
  mkSystem = name: nixpkgs: nixpkgs.lib.nixosSystem ({
    system = "x86_64-linux";
    modules = [
      {
        _module.args = inputs;
        networking.hostName = name;
        system.configurationRevision = self.rev or "dirty";
        documentation.enable = false;
      }
      (./. + "/${name}.nix")
      (./. + "/hardware/${name}.nix")
    ];
  });
in {
    max = mkSystem "max" inputs.pkgs-2105;
}
