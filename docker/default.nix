pkgs: with pkgs;
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
    name = "bundle";
    tag = "latest";

    contents = [
      pkgs.unstable.busybox
      pkgs.unstable.less
      pkgs.unstable.ncurses
      pkgs.unstable.openssh

      pkgs.mypkg.nvim
      pkgs.mypkg.clangd
      pkgs.unstable.global
      pkgs.unstable.universal-ctags

      pkgs.mypkg.tmux
      pkgs.unstable.perl

      pkgs.mypkg.myfish

      pkgs.unstable.wget
      pkgs.unstable.tree
      pkgs.unstable.ripgrep
      pkgs.unstable.tig
      pkgs.unstable.git
      pkgs.unstable.fzf
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
