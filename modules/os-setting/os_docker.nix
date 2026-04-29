{
  internal.nixosModules.os_docker = { pkgs, ... }: {
    # List packages installed in system profile. To search, run:
    environment.systemPackages = [
      pkgs.docker-compose
    ];

    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };
}

