{
  # Shares /home/max/project to the Windows host over SMB. The files stay on the
  # guest's ext4, so git/nix/nvim inside the VM keep native POSIX semantics and
  # speed; only the host pays the network-filesystem cost. The reverse setup
  # (a VMware HGFS shared folder) would put the tree on NTFS behind vmhgfs-fuse,
  # which loses the permission bits and symlinks this repo's flake needs.
  internal.nixosModules.samba_project = { ... }: {
    services.samba = {
      enable = true;

      # NetBIOS name service, so the host can use \\vm instead of a DHCP
      # address that moves whenever the lease does.
      nmbd.enable = true;

      # On by default, but it only matters for AD/NT4 domain membership; a
      # standalone server authenticates from its own smbpasswd file.
      winbindd.enable = false;

      # Redundant while networking.firewall.enable is false in os_base1, but it
      # keeps the share reachable if the firewall is ever turned back on.
      openFirewall = true;

      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "nixos vm";
          "server role" = "standalone server";
          # No anonymous fallback: a failed login must fail, not silently
          # downgrade to the guest account.
          "map to guest" = "never";
          # Reachable only from the VMware NAT subnet and the guest itself.
          "hosts allow" = "192.168.238.0/24 127.0.0.1";
          "hosts deny" = "0.0.0.0/0";
        };

        project = {
          path = "/home/max/project";
          browseable = "yes";
          "read only" = "no";
          "valid users" = "max";
          # Everything written from Windows lands as max:users, so the guest-side
          # tooling doesn't trip over files it can't rewrite.
          "force user" = "max";
          "force group" = "users";
          "create mask" = "0644";
          "directory mask" = "0755";
          # Windows has no POSIX symlinks; resolve them server-side so the trees
          # under ~/project still look normal from Explorer. Confined to the
          # share -- wide links would expose the rest of the filesystem.
          "follow symlinks" = "yes";
          "wide links" = "no";
        };
      };
    };
  };
}
