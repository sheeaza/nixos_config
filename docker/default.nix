{ pkgs, upkgs, bundle }: with upkgs;
let
  adduser = { user, uid, gid ? uid }: [
    (
      writeTextDir "etc/shadow" ''
	${user}:!:::::::
      ''
    )
    (
      writeTextDir "etc/passwd" ''
	${user}:x:0:0::/home/${user}:/bin/fish
      ''
    )
    (
      writeTextDir "etc/group" ''
        ${user}:x:0:
      ''
    )
    (
      writeTextDir "etc/gshadow" ''
        ${user}:x::
      ''
    )
  ];
  uuser = "max";
in
  pkgs.dockerTools.buildImage {
  # pkgs.dockerTools.buildLayeredImage {
    name = "bundle";
    tag = "latest";

    contents = [
      upkgs.busybox
      bundle
      upkgs.ncurses
      upkgs.openssh
    ] ++ adduser { uid = 0; user = uuser; };

    # fakeRootCommands = ''
      # mkdir -p ./home/${uuser}
      # chown 1000 ./home/$(uuser}
    # '';
    # runAsRoot = ''
      # mkdir -p /data
    # '';
    # extraCommands = ''
      # mkdir -p /home/max
      # mkdir /tmp
      # chmod 1777 /tmp
    # '';

    config = {
      Cmd = "fish";
      Env = [
      ];
    };
  }
