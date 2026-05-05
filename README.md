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
- `iso-installer` — graphical Calamares installer — recommended for end-user installs
- `iso` — minimal live environment — useful for rescue / manual partitioning

#### Logging in to the live USB

Both `mykolas` and `root` have the initial password **`nixos`** set via `initialPassword`. Both hosts explicitly set `users.mutableUsers = true`, which means:
- `initialPassword` only applies the **first time** the user is created (live ISO or fresh install first boot)
- After that, use `passwd` to set a real password — `nixos-rebuild switch` will never reset it
- The plain-text password is world-readable in the Nix store, so **change it with `passwd` on first login**

| Account | Password |
|---------|----------|
| `mykolas` | `nixos` |
| `root` | `nixos` |

> **Note:** `useTextGreeter` must be **off** when sysc-greet is enabled — enabling it causes a PAM `AUTH_ERR` because tuigreet and sysc-greet both try to own the greetd session. Both hosts have this set correctly.

### Validate configs

Dry-run eval per host and/or `nix flake check`:

```sh
nix run github:MykolaSuprun/nixos-flakes-config#nixos-check
```

### Build and switch the current host

```sh
nix run github:MykolaSuprun/nixos-flakes-config#nixos-build
```

### Flash an ISO to a USB drive

```sh
nix run github:MykolaSuprun/nixos-flakes-config#nixos-flash
```


### Using a local checkout

Set `FLAKE_REF=.` to point any of the above scripts at the local tree instead of GitHub:

```sh
FLAKE_REF=. nix run .#nixos-iso
FLAKE_REF=. nix run .#nixos-check
FLAKE_REF=. nix run .#nixos-build
nix run .#nixos-flash
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
