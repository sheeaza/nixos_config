{ inputs, ... }:
{
  internal.unstableOverlays.cus-claude-code =
    final: prev:
    let
      base = (inputs.claude-code.overlays.default final prev).claude-code;
    in
    {
      cus-claude-code = final.symlinkJoin {
        name = "claude-code";
        paths = [ base ];
        nativeBuildInputs = [ final.makeWrapper ];
        postBuild =
          let
            settingsFile = ./claude-settings.json;
            # Tools claude code shells out to; prefixed onto PATH, not hardcoded in the JSON.
            toolPath = final.lib.makeBinPath [
              final.nodejs
              final.procps
              final.ripgrep
              final.fd
              final.jq
              final.python3
              final.bubblewrap
              final.socat
              final.cus-clangd
            ];
          in
          ''
            # Passed on every launch, layered over ~/.claude settings files.
            wrapProgram $out/bin/claude \
              --add-flags "--settings ${settingsFile}" \
              --prefix PATH : ${toolPath}
          '';
      };
    };
  perSystem = { pkgs, ... }: {
    packages.myclaude-code = pkgs.unstable.cus-claude-code;
  };
}
