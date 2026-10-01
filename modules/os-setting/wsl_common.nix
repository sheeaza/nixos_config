{ inputs, ... }:
{
  # Everything the wsl* hosts had duplicated verbatim. Each host keeps only what
  # genuinely differs between them: its nixpkgs platform and the extra modules it
  # composes on top.
  internal.nixosModules.wsl_common =
    { lib, pkgs, ... }:
    {
      # Pulled in here rather than listed by each host: wsl.enable below is
      # meaningless without it, so the option and the module that defines it
      # belong together.
      imports = [ inputs.nixos-wsl.nixosModules.default ];

      wsl.enable = true;

      environment.systemPackages = [
        pkgs.bashInteractive
        pkgs.sshfs
        pkgs.xclip
      ];

      networking = {
        # mkDefault so a host that wants a distinct name can just set it.
        hostName = lib.mkDefault "wsl";

        # os_base1 enables NetworkManager, which unconditionally switches on
        # wpa_supplicant to drive wifi over DBus. WSL's network interfaces come
        # from the Windows host and none of them are wireless, so that is a
        # daemon with nothing to manage. mkForce because NetworkManager sets it
        # as a plain definition, not a default.
        wireless.enable = lib.mkForce false;
      };
    };
}
