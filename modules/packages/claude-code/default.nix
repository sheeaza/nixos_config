{ inputs, ... }:
{
  internal.unstableOverlays = {
    claude-code = inputs.claude-code.overlays.default;
    claude-code-wrapper = final: prev: {
      claude-code = final.symlinkJoin {
        name = "claude-code";
        paths = [ prev.claude-code ];
        nativeBuildInputs = [ final.makeWrapper ];
        postBuild =
          let
            settingsFile = ./claude-settings.json;
            # Tools claude code shells out to; prefixed onto PATH, not hardcoded in the JSON.
            toolPath = final.lib.makeBinPath [
              final.nodejs
              final.procps
              final.ripgrep
              final.bubblewrap
              final.socat
              final.clangd
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
  };
  perSystem = { pkgs, ... }: {
    packages.myclaude-code = pkgs.unstable.claude-code;
  };
}
