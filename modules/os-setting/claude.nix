{
  internal.nixosModules.claude =
    { lib, pkgs, ... }:
    let
      settingsFile = ./claude-settings.json;
      # Tools claude code shells out to; prefixed onto PATH, not hardcoded in the JSON.
      toolPath = lib.makeBinPath [
        pkgs.nodejs
        pkgs.procps
        pkgs.ripgrep
        pkgs.bubblewrap
        pkgs.socat
        pkgs.unstable.clangd
      ];
      # Passed on every launch, layered over ~/.claude settings files.
      claude-code = pkgs.symlinkJoin {
        name = "claude-code";
        paths = [ pkgs.unstable.claude-code ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/claude \
            --add-flags "--settings ${settingsFile}" \
            --prefix PATH : ${toolPath}
        '';
      };
    in
    {
      environment.systemPackages = [
        claude-code
      ];

      # now unneeded, set in unstable pkg
      # but keep it here, incase later switch to stable one
      nixpkgs.config.allowUnfree = true;
    };
}
