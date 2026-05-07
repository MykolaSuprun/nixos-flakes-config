# nixos-flakes-config

Personal NixOS configuration managed with [flake-parts](https://github.com/hercules-ci/flake-parts) and [import-tree](https://github.com/vic/import-tree). All files under `flake/` are auto-discovered — no manual registration needed.

Uses [Determinate Nix](https://determinate.systems/) on all hosts.

## Hosts

| Host | Description |
|------|-------------|
| `geks-nixos` | Main desktop (AMD, NixOS, Hyprland) |
| `geks-zenbook` | Laptop (Intel, NixOS, Hyprland + Plasma 6) |
| `geks-wsl` | WSL2 minimal environment |

## Disk layout (geks-nixos and geks-zenbook)

Both physical hosts use the layout declared in `flake/hosts/<host>/_disk-config.nix`,
applied by [disko](https://github.com/nix-community/disko) at install time:

```
GPT
├── ESP        512 MiB   vfat    /boot         umask=0077
└── cryptroot  remainder LUKS2 → btrfs
    ├── @          →  /          compress=zstd:3, noatime
    ├── @home      →  /home      compress=zstd:3, noatime
    ├── @nix       →  /nix       compress=zstd:3, noatime
    ├── @log       →  /var/log   compress=zstd:3, noatime  (neededForBoot)
    └── @swap      →  /.swapvol  noatime   (geks-zenbook only — 32 GiB swapfile for hibernation)
```

---

## Installing NixOS from scratch

Installation runs from a **standard NixOS minimal ISO** — no custom ISO is needed.
The `nixos-install` script handles everything: disk partitioning, LUKS2 encryption,
btrfs formatting, and installation of the exact configuration defined in this flake.

### Step 1 — Create a bootable USB

There are two options. Both produce a USB you boot to get a shell, then continue with Step 2.

#### Option A — Standard NixOS minimal ISO

Download the latest **NixOS minimal ISO** from <https://nixos.org/download>
(x86\_64-linux, "Minimal ISO image").

Flash it to USB:

```sh
nix run github:MykolaSuprun/nixos-flakes-config#nixos-flash -- ~/Downloads/nixos-minimal-*.iso
```

`nixos-install` is fetched from GitHub at the start of Step 2 (internet required from the USB).

#### Option B — nixos-installer ISO (nixos-install pre-installed)

Build a custom ISO that ships `nixos-install` baked in (no extra download needed on the USB):

```sh
nix run github:MykolaSuprun/nixos-flakes-config#nixos-iso
```

This builds `flake/hosts/installer/default.nix` — a minimal live image with `nixos-install`
and its dependencies in the closure. The ISO lands in `./result/iso/`. Flash it:

```sh
nix run github:MykolaSuprun/nixos-flakes-config#nixos-flash -- ./result/iso/nixos-installer-*.iso
```

Or let the flash picker find it automatically:

```sh
nix run github:MykolaSuprun/nixos-flakes-config#nixos-flash
```

### Step 2 — Boot the USB and run the installer

Boot the target machine from the USB. Once at the shell:

- **Option A** (standard ISO): fetch and run the installer:

  ```sh
  nix run github:MykolaSuprun/nixos-flakes-config#nixos-install
  ```

- **Option B** (nixos-installer ISO): `nixos-install` is already in `$PATH`:

  ```sh
  nixos-install
  ```

The script will interactively:

1. Configure Nix binary caches (nixos.org, nix-community, Determinate) so nothing
   needs to be compiled from source during install
2. Discover all installable hosts from the flake — pick `geks-nixos` or `geks-zenbook`
   via fzf
3. List all attached disks — pick the installation target
   (**⚠ ALL DATA ON THE SELECTED DISK WILL BE PERMANENTLY AND IRREVERSIBLY ERASED**)
4. Ask for explicit confirmation (`yes` to proceed)
5. Run `disko-install`, which:
   - Partitions the disk (GPT: 512 MiB ESP + encrypted remainder)
   - Opens LUKS2 and formats the container as btrfs with all subvolumes
   - Installs NixOS from this flake's exact configuration into the new filesystem
   - Writes EFI boot entries

Internet access is required during installation.

To use a local checkout of this repo instead of fetching from GitHub:

```sh
FLAKE_REF=/path/to/nixconf nix run github:MykolaSuprun/nixos-flakes-config#nixos-install
```

### Step 3 — Reboot and change passwords

After the installer finishes, reboot:

```sh
sudo reboot
```

Log in. The initial password for all accounts is **`nixos`** — change it immediately:

```sh
passwd          # change mykolas password
sudo passwd     # change root password
```

| Account | Initial password |
|---------|-----------------|
| `mykolas` | `nixos` |
| `root` | `nixos` |

> Both hosts set `users.mutableUsers = true`. `initialPassword` only applies on first
> user creation — subsequent `nixos-rebuild switch` runs will never reset it. However
> the plain-text value is world-readable in the Nix store, so change it before the
> machine goes online.

### Step 4 — (geks-zenbook only) Enable hibernation

The btrfs swapfile's physical extent offset cannot be known statically — it is
determined at format time. After the first boot:

```sh
sudo btrfs inspect-internal map-swapfile -r /.swapvol/swapfile
```

Add the printed integer to `flake/hosts/geks-zenbook/_configuration.nix`:

```nix
boot.kernelParams = [ "resume_offset=<N>" ];
```

Then rebuild and switch:

```sh
nixos-build
```

---

## Day-to-day commands

### Build the nixos-installer ISO

```sh
nixos-iso
# or:
nix run github:MykolaSuprun/nixos-flakes-config#nixos-iso
```

### Build and switch the running system

Builds with `nh os switch`, switches the running system, then auto-commits the config
with the generation number and a summary of changed inputs/files:

```sh
nixos-build
```

Or from any machine with Nix:

```sh
nix run github:MykolaSuprun/nixos-flakes-config#nixos-build
```

### Validate configs without switching

Dry-run eval per host and/or full `nix flake check`, with host multi-select via fzf:

```sh
nixos-check
# or:
nix run github:MykolaSuprun/nixos-flakes-config#nixos-check
```

### Rebuild from GitHub (no local checkout needed)

Pick a host and action (`switch` / `boot` / `test` / `dry-activate`) via fzf:

```sh
nix run github:MykolaSuprun/nixos-flakes-config#nixos-remote-build
```

Set `FLAKE_REF=.` to use a local tree instead:

```sh
FLAKE_REF=. nix run .#nixos-remote-build
```

### Update flake inputs

Interactive — select inputs to update via fzf (Tab = multi-select, Ctrl-A = all):

```sh
nix-update
# or:
nix run github:MykolaSuprun/nixos-flakes-config#nix-update
```

### Using a local checkout for any script

```sh
FLAKE_REF=. nix run .#nixos-install
FLAKE_REF=. nix run .#nixos-check
FLAKE_REF=. nix run .#nixos-build
FLAKE_REF=. nix run .#nixos-remote-build
nix run .#nixos-flash
```

---

## Repository structure

```
flake/
  hosts/
    geks-nixos/    # AMD desktop
    geks-zenbook/  # Intel laptop
    geks-wsl/      # WSL2 minimal
    Each host contains: default.nix  _configuration.nix  _hardware.nix  _disk-config.nix
  packages/        # nixos-install  nixos-flash  nixos-build  nixos-check
                   # nixos-remote-build  nix-update
nixos/             # Shared NixOS feature modules (each gated by a myconf.* enable flag)
home-manager/      # Home Manager modules and per-user configs
lib/               # Config generators (helix, zsh, tmux, kitty, wezterm, …)
overlays/          # Nixpkgs overlays
pkgs/              # Custom packages
templates/         # nix flake init templates (go, haskell, python-uv, scala, java)
```

---

## fzf keybindings (all interactive scripts)

| Key | Action |
|-----|--------|
| `j` / `k` | Down / Up |
| `g` / `G` | First / Last |
| `Ctrl-d` / `Ctrl-u` | Half-page down / up |
| `Tab` | Multi-select (where applicable) |
| `Enter` | Confirm |
| `Esc` / `Ctrl-c` | Abort |
