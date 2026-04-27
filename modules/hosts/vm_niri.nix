{
  config,
  inputs,
  ...
}:
let local_config = { pkgs, ... }: {
  # enable open vm tool
  virtualisation.vmware.guest.enable = true;

  # docker
  virtualisation.docker.enable = true;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = [
    pkgs.unstable.lua-language-server
  ];

  networking = {
    hostName = "vm";
  };

  nixpkgs.hostPlatform = "x86_64-linux";
};
in
{
  flake.nixosConfigurations.vm_niri = inputs.pkgs-stable.lib.nixosSystem {
    modules = [
      config.flake.nixosModules.nixpkgs
      config.flake.modules.nixos.boot
      config.flake.nixosModules.vm_hw
      config.flake.nixosModules.os_niri
      config.flake.nixosModules.max
      local_config
    ];
  };
}
