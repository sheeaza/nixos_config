{
  config,
  inputs,
  ...
}:
let local_config = { pkgs, ... }: {
  # enable open vm tool
  virtualisation.vmware.guest.enable = true;

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
  flake.nixosConfigurations.vm_headless = inputs.pkgs-stable.lib.nixosSystem {
    modules = [
      config.internal.nixosModules.nixpkgs
      config.internal.nixosModules.boot
      config.internal.nixosModules.hw_vm
      config.internal.nixosModules.os_base1
      config.internal.nixosModules.os_docker
      config.internal.nixosModules.os_pkgs1
      config.internal.nixosModules.claude
      config.internal.nixosModules.max
      local_config
    ];
  };
}
