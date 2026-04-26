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
};
in
{
  flake.nixosConfigurations.vm_niri = inputs.pkgs-stable.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      config.flake.modules.nixos.boot
      config.flake.nixosModules.vm_hw
      config.flake.nixosModules.os_niri
      config.flake.nixosModules.sddm_niri
      config.flake.nixosModules.max
      local_config
      {
        nixpkgs.overlays = [
          config.flake.overlays.unstable
        ];
      }
    ];
  };
}

