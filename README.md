# nixos_config

takes https://github.com/NobbZ/nixos-config as a reference

## Layout

The flake uses [flake-parts](https://flake.parts) with
[import-tree](https://github.com/vic/import-tree): every `.nix` file under
`modules/` is loaded automatically, so there is no import list to maintain.
Each file registers what it provides into the `internal.*` options declared in
`modules/internal.nix`:

| option                        | what goes in it                                                                  |
| ----------------------------- | -------------------------------------------------------------------------------- |
| `internal.nixosModules.X`     | a NixOS module, referenced by hosts as `...nixosModules.X`                       |
| `internal.unstableOverlays.X` | an overlay, applied to `pkgs.unstable` automatically                             |
| `internal.stableOverlays.X`   | an overlay, applied to the flake's own (stable) set and to the hosts' `nixpkgs`  |

Name a file after the module it registers.

Packages come from two sets: editors and daily-driver tools (`myfish`, `tmux`,
`neovim`, ...) from `pkgs.unstable`; compilers and dev shells from stable.

## Adding things

- **A package**: create `modules/packages/<name>/default.nix` that sets
  `internal.unstableOverlays.<name>`, plus `perSystem.packages.my<name>` to build it
  with `nix build .#my<name>`. Nothing else needs editing.
- **A host**: create `modules/hosts/<name>.nix` defining
  `flake.nixosConfigurations.<name>` from a list of
  `config.internal.nixosModules.*`.
- **A check**: add a script under `modules/checks/` and wire it in
  `modules/checks/checks.nix`; run with `nix build .#checks.<system>.<name>`.

Binary caches are listed once, in `nixConfig` in `flake.nix`; the NixOS
`nix.settings` reads them from there.
