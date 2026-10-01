# Regression checks for the wrapped packages, exposed as checks.<system>.*.
#
# Run all of them with `nix flake check`, or one at a time with
# `nix build .#checks.x86_64-linux.<name>`.
#
# The test logic lives in the sibling .sh files, not inline here: keeping it in
# real shell scripts preserves syntax highlighting, lets shellcheck run over
# them, and keeps Nix's ''...'' escaping out of the assertions. This module only
# builds the runtime environment and hands each script the store paths it needs
# through the environment, so the scripts contain no Nix interpolation at all.
{
  perSystem =
    { pkgs, ... }:
    let
      # Each check runs in a plain runCommand. `set -u` in the scripts catches a
      # typo'd variable name, which would otherwise read as empty and quietly
      # weaken an assertion.
      mkCheck =
        {
          name,
          script,
          nativeBuildInputs ? [ ],
          env ? { },
        }:
        pkgs.runCommand "check-${name}"
          (
            env
            // {
              nativeBuildInputs = nativeBuildInputs ++ [
                pkgs.gnugrep
                pkgs.gnused
                pkgs.coreutils
              ];
              # Passed rather than interpolated so the scripts stay runnable as
              # ordinary shell.
              LIB = ./lib.sh;
            }
          )
          ''
            bash ${script}
          '';

      # closureInfo gives the scripts a store-paths manifest to grep. The nix
      # daemon is unreachable from inside the sandbox, so `nix path-info` is not
      # an option for the closure assertions.
      closureOf = pkg: pkgs.closureInfo { rootPaths = [ pkg ]; };

      inherit (pkgs.unstable)
        myfish
        tmux
        neovim
        alacritty
        niri-cfg
        ;
    in
    {
      checks = {
        fish = mkCheck {
          name = "fish";
          script = ./fish.sh;
          nativeBuildInputs = [
            # fzf and git are deliberately NOT in the myfish closure -- the system
            # installs them separately through os_pkgs1. The vendored
            # key-bindings.fish bails out with "fzf was not found in path" without
            # fzf, and fish_prompt's git segment needs git, so both must be on
            # PATH to reproduce a real login shell.
            pkgs.unstable.fzf
            pkgs.git
          ];
          env = {
            FISH = "${myfish}/bin/fish";
            FISH_CLOSURE = closureOf myfish;
          };
        };

        tmux = mkCheck {
          name = "tmux";
          script = ./tmux.sh;
          nativeBuildInputs = [
            # tmux.sh's _pane_info pipeline. Without these the status-line jobs
            # fail silently and the segments render empty.
            pkgs.procps
            pkgs.gawk
          ];
          env = {
            TMUX_BIN = "${tmux}/bin/tmux";
            TMUX_CLOSURE = closureOf tmux;
          };
        };

        nvim = mkCheck {
          name = "nvim";
          script = ./nvim.sh;
          env = {
            NVIM = "${neovim}/bin/nvim";
            NVIM_CLOSURE = closureOf neovim;
          };
        };

        # alacritty and niri-cfg share a check: niri's config.kdl substitutes the
        # wrapped alacritty into its Mod+T binding, so the interesting assertion
        # spans both packages.
        terminal = mkCheck {
          name = "terminal";
          script = ./terminal.sh;
          env = {
            ALACRITTY = "${alacritty}/bin/alacritty";
            NIRI_CFG = niri-cfg;
            NIRI_BIN = "${pkgs.niri}/bin/niri";
            ALAC_WRAPPED_BIN = "${alacritty}/bin/alacritty";
          };
        };
      };
    };
}
