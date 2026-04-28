{ inputs, ... }:
{
  internal.nixosModules.dms_greeter = { pkgs, ... }:
  {
    imports = [
      inputs.dms.nixosModules.greeter
    ];
    programs.dank-material-shell.greeter = {
      enable = true;
      compositor.name = "niri";
    };
  };
}
