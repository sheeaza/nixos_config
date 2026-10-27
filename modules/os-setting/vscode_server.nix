{ inputs, ... }:
{
  internal.nixosModules.vscode_server = {
    imports = [
      inputs.vscode-server.nixosModules.default
    ];

    services.vscode-server.enable = true;
    systemd.user.services.auto-fix-vscode-server = {
      enable = true;
    };
  };
}
