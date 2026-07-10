# AGENTS.md — Guide for AI Coding Agents

This file provides context and rules for AI agents (e.g. Avante) working in this repository.

## Project Overview

Personal NixOS configuration managed with [flake-parts](https://github.com/hercules-ci/flake-parts) and [import-tree](https://github.com/vic/import-tree). Uses [Determinate Nix](https://determinate.systems/) on all hosts. The desktop environment is Hyprland launched via UWSM (systemd-managed Wayland sessions).

### Hosts

| Host | Description | Display Manager | GPU |
|------|-------------|-----------------|-----|
| `geks-nixos` | AMD desktop, Hyprland + gaming | greetd + sysc-greet | AMD dGPU (7900 XTX) + AMD iGPU |
| `geks-zenbook` | Intel laptop, Hyprland + Plasma 6 | SDDM (Wayland) | Intel Iris/Xe iGPU |
| `geks-wsl` | WSL2 minimal environment | N/A | N/A |

### Repository Structure

```
flake/
  hosts/
    geks-nixos/      # AMD desktop — default.nix, _configuration.nix, _hardware.nix, _disk-config.nix
    geks-zenbook/    # Intel laptop — same layout
    geks-wsl/        # WSL2 minimal — same layout
    installer/       # Custom installer ISO
  modules.nix        # Exposes all nixos/ and home-manager/modules/ as flake outputs
                      #   (flake.nixosModules.*, flake.homeManagerModules.*)
  packages/          # CLI tools only: nixos-install, nixos-flash, nixos-build, nixos-check,
                     #   nixos-remote-build, nixos-iso, nix-update, hypr-layout-picker
nixos/               # Shared NixOS feature modules — each gated by myconf.nixos.<name>.enable
home-manager/
  modules/           # Shared Home Manager feature modules — each gated by myconf.<name>.enable or hyprconf.*
  users/mykolas/     # Per-user configuration and dotfiles
    config/          # Raw dotfiles (hyprland, uwsm, swaync, hyprlock, wallpapers, etc.)
lib/                 # Config generators (helix, zsh, tmux, kitty, wezterm, rofi, ghostty)
overlays/            # Nixpkgs overlays
templates/           # nix flake init templates (go, haskell, python-uv, scala, java)
scripts/             # Standalone shell scripts
```

### Key Architectural Patterns

- **Feature modules**: All NixOS modules in `nixos/` and Home Manager modules in `home-manager/modules/` are auto-imported by each host's `default.nix`. Each module is gated by an enable flag (`myconf.nixos.<name>.enable` for NixOS, `myconf.<name>.enable` or `hyprconf.*` for HM). Never import a module directly in a host config — always add an enable flag and set it in the host's `_configuration.nix` or `home-*.nix`.
- **Host-specific config**: Host differences live in `flake/hosts/<host>/_configuration.nix` (NixOS-level) and `home-manager/users/mykolas/home-<host>.nix` (HM-level). Shared config lives in the feature modules.
- **Hyprland + UWSM**: Hyprland is launched via UWSM (`programs.hyprland.withUWSM = true`). UWSM env files are deployed to `~/.config/uwsm/` by `home-manager/modules/hyprland/settings.nix`. The `env` file is shared across all hosts; `env-hyprland` is host-conditional (e.g. `AQ_DRM_DEVICES` only set on `geks-nixos` where dual-GPU udev symlinks exist).
- **Hyprland config type**: Hyprland is configured via Lua (`configType = "lua"`), with the entry point `require("hyprland-dynamic")` in `~/.config/hypr/`. Lua files are symlinked from the repo to `~/.config/hypr/lua/` via live-links for live editing.
- **Catppuccin theming**: Theming is managed by catppuccin-nix + stylix. The Catppuccin palette is Nix-generated into `catppuccin-palette.lua` — do not edit that file manually.
- **Wrapped packages**: Removed. Previously kitty, helix, tmux, wezterm, zsh, rofi, and ghostty were wrapped via `inputs.wrappers` in `flake/packages/`. Their configurations have been ported to Home Manager modules in `home-manager/modules/` (each gated by `myconf.<name>.enable`). CLI tool packages (nixos-build, nixos-check, nixos-install, nixos-iso, nixos-flash, nixos-remote-build, nix-update, hypr-layout-picker) remain as flake packages and are still accessed via `wrappedPkgs` (now a misnomer — it's all flake `perSystem.packages`).
- **SSH/GPG agent**: SSH key passphrase caching is handled by `gpg-agent` with `enableSshSupport = true` on all hosts (including WSL). The NixOS `ssh-agent` is explicitly disabled (`startAgent = false`) to avoid `SSH_AUTH_SOCK` conflicts. HM's `gpg-agent` module creates a socket-activated `gpg-agent-ssh.socket` systemd user unit and a `set-SSH_AUTH_SOCK.service` that exports `SSH_AUTH_SOCK` into the D-Bus/systemd environment (so GUI apps launched via `uwsm app` also see it). SSH client config lives in `home-manager/modules/ssh.nix` (gated by `myconf.ssh.enable`) and uses the new `programs.ssh.settings."*"` API with upstream OpenSSH directive names. Agent forwarding is disabled globally (`ForwardAgent = false`) for security — enable per-host in `programs.ssh.settings` if needed. Pinentry is configured per-host: `pinentry-qt` on desktop hosts (works on Wayland via the Nixpkgs qtwayland wrapper, with `QT_QPA_PLATFORM=wayland;xcb` set in the UWSM env file), `pinentry-tty` on WSL. `allow-loopback-pinentry` is set in gpg-agent extraConfig on all hosts for TTY fallback when no display is available (SSH sessions, TTY-only contexts). The NixOS-level `programs.gnupg.agent` is not used — HM's `services.gpg-agent` handles everything.

## Rules for AI Agents

### 1. Always Test Config Changes with a Build

Nix configuration changes must be validated before considering the task complete. Use one of:

```sh
# Dry-run evaluation of a specific host (fastest, recommended for most changes):
nix build .#nixosConfigurations.geks-zenbook.config.system.build.toplevel --dry-run --show-trace

# Or use the interactive check script (select host and mode):
nix run .#nixos-check

# Full flake check (evaluates all outputs — slower):
nix flake check . --show-trace
```

**Always run a dry-run build for the affected host(s) after making changes.** If the build fails, fix the errors before reporting completion.

### 2. Understand Host Conditionality

Many configs are shared across hosts but need host-specific values. Check `config.hyprconf.target` (values: `"geks-zenbook"` or `"geks-nixos"`) and `config.catppuccin.flavor` to conditionally set values. Never assume a device path, GPU setup, or display configuration applies to all hosts.

### 3. Respect Existing Conventions

- Use 2-space indentation in Nix files (matching existing style).
- Use `lib.mkIf`, `lib.mkMerge`, `lib.mkOption`, and `lib.mkEnableOption` for conditional and modular config.
- Gate new modules behind enable flags, never import them unconditionally.
- Keep comments in English, concise, and explain *why* (not *what*).
- Use `lib.mkDefault` / `lib.mkForce` judiciously when overriding values from shared modules.

### 4. Do Not Edit Generated Files

- `home-manager/users/mykolas/config/hyprland/lua/catppuccin-palette.lua` — generated from `catppuccin.flavor` and `catppuccin.accent` in `settings.nix`.
- Files under `~/.config/hypr/lua/` are symlinked from the repo — edit the source in `home-manager/users/mykolas/config/hyprland/lua/`, not the deployed symlinks.

### 5. Flake Inputs

Flake inputs are defined in `flake.nix`. When adding a new input, follow the existing pattern (URL, `inputs.nixpkgs.follows = "nixpkgs"` where appropriate). Run `nix flake lock --update-input <name>` after adding.

### 6. Commits

Only commit when explicitly asked by the user. Use the existing commit style — the `nixos-build` script auto-commits with the generation number. For manual commits, use a concise message describing the change.

### 7. UWSM / Hyprland Launch

- UWSM env files are in `home-manager/users/mykolas/config/uwsm/` and deployed via `home-manager/modules/hyprland/settings.nix`.
- `env` is shared across all hosts. `env-hyprland` is host-conditional.
- `AQ_DRM_DEVICES` must only be set on hosts with the corresponding udev symlinks (`/dev/dri/igpu`, `/dev/dri/dgpu`).
- HM's Hyprland systemd integration is disabled (`systemd.enable = false`) — UWSM manages the session lifecycle. User services bind to `wayland-session@hyprland.desktop.target` or `graphical-session.target`.
- Apps inside Hyprland are launched via `uwsm app -s <slice> -- <cmd>` where slices are `a` (app-graphical), `b` (background-graphical), `s` (session-graphical).

