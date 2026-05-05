# nixos-flakes-config

Personal NixOS configuration managed with [flake-parts](https://github.com/hercules-ci/flake-parts) and [import-tree](https://github.com/vic/import-tree). All files under `flake/` are auto-discovered — no manual registration needed.

Uses [Determinate Nix](https://determinate.systems/) on all hosts.

## Hosts

| Host | Description |
|------|-------------|
| `geks-nixos` | Main desktop (NixOS, Hyprland) |
| `geks-zenbook` | Laptop (NixOS, Hyprland) |
| `geks-wsl` | WSL2 minimal environment |

## Quick commands

### Build a NixOS installer ISO

Interactive — picks host and image variant via fzf (works on any machine with Nix):

```sh
nix run github:MykolaSuprun/nixos-flakes-config#nixos-iso
```

Variants:
- `iso-installer` — graphical Calamares installer *(default choice)*
- `iso` — minimal live environment

### Validate configs

Dry-run eval per host and/or `nix flake check`:

```sh
nix run github:MykolaSuprun/nixos-flakes-config#nixos-check
```

### Build and switch the current host

```sh
nix run github:MykolaSuprun/nixos-flakes-config#nixos-build
```

### Using a local checkout

Set `FLAKE_REF=.` to point any of the above scripts at the local tree instead of GitHub:

```sh
FLAKE_REF=. nix run .#nixos-iso
FLAKE_REF=. nix run .#nixos-check
FLAKE_REF=. nix run .#nixos-build
```

## Structure

```
flake/
  hosts/          # Per-host flake-parts modules (nixosConfigurations)
  packages/       # Utility scripts exposed as flake packages
nixos/            # Shared NixOS modules (imported by all hosts)
home-manager/     # Home Manager modules and per-user configs
lib/              # Config file generators (helix, zsh, tmux, …)
overlays/         # Nixpkgs overlays
pkgs/             # Custom packages
```

## Keybindings (fzf pickers)

All interactive scripts use vim-style navigation:

| Key | Action |
|-----|--------|
| `j` / `k` | Down / Up |
| `g` / `G` | First / Last |
| `Ctrl-d` / `Ctrl-u` | Half-page down / up |
| `Tab` | Multi-select (where applicable) |
| `Enter` | Confirm |
