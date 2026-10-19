# AGENTS.md — Guide for AI Coding Agents

This file provides context and rules for AI agents (e.g. Avante) working in this repository.

## Project Overview

Personal NixOS configuration managed with [flake-parts](https://github.com/hercules-ci/flake-parts) and [import-tree](https://github.com/vic/import-tree). Uses [Determinate Nix](https://determinate.systems/) on all hosts. The desktop environment is Hyprland launched via UWSM (systemd-managed Wayland sessions).

### Hosts

| Host | Description | Display Manager | GPU |
|------|-------------|-----------------|-----|
| `geks-nixos` | AMD desktop, Hyprland + gaming | greetd + sysc-greet | AMD dGPU (7900 XTX) + AMD iGPU |
| `geks-zenbook` | Intel laptop, Hyprland + Plasma 6 | SDDM (Wayland) | Intel Iris/Xe iGPU + NVIDIA RTX 4060 Laptop dGPU (present, but **no NVIDIA driver is configured** — no `hardware.nvidia` anywhere in this repo) |
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
- **Herdr**: Herdr is an agent multiplexer (like tmux for AI agents) configured via `home-manager/modules/herdr.nix` (gated by `myconf.herdr.enable`). Its config is a live-linked TOML file in the checkout — `home-manager/users/mykolas/config/herdr/config.toml` is symlinked into `~/.config/herdr/config.toml` by `lib/live-links.nix` (same mechanism as the Hyprland Lua config): edit it and reload with `prefix+Shift+r` / `herdr server reload-config`, no rebuild. Nix no longer generates the file (`programs.herdr` runs with no `settings`; herdr supports no config includes). Never run `herdr config reset-keys` — it rewrites the file in place. Bindings are tmux-motion-compatible: prefix is `ctrl+e` (NOT tmux's `Ctrl+Space` — that stays tmux's so embedded sessions keep working), pane navigation uses `prefix+h/j/k/l` plus `Alt+Shift+h/j/k/l` direct chords, pane swapping uses `prefix+Shift+h/j/k/l`, splits use `prefix+-` and `prefix+v`, tabs use `prefix+c/n/p/1..9`. Theme: static `catppuccin-latte` initial value with `auto_switch = true` — herdr follows the host terminal's light/dark at runtime (the flavor is no longer Nix-derived; herdr runs only on geks-nixos = latte).

  **Plugins**: herdr's plugin registry (`~/.config/herdr/plugins.json` — a
  writable JSON array herdr rewrites on link/enable/install; never generate or
  symlink it from Nix) is managed **declaratively** by the flake input
  `nix-herdr-manager` (GitLab `mykolas-open/nix-herdr-manager`), enabled as
  `programs.herdr-hpm` in `home-geks-nixos.nix` with **three entries**:
  `inputs.herdr-vimnav.packages.<system>.default` (the preview-grid plugin,
  `gitlab:mykolas-open/herdr-vimnav`, GitHub mirror `MykolaSuprun/herdr-vimnav`)
  plus the manager's two curated upstream packages
  `herdr-simple-switcher` (bash) and `herdr-configurable-picker` (Rust) — all
  three are bare-package entries keyed by `passthru.herdrPluginId`. The two
  curated packages replace plugins that used to be `herdr plugin install`ed
  (the old install-managed dirs under `plugins/github/` are orphans to delete
  once the first Nix-managed rebuild lands).

  At HM activation (after `linkGeneration`) the manager runs
  `herdr plugin link <store>/share/herdr/plugins/<id> --enabled` for every
  declared plugin, **unlinks store links that are no longer declared**
  (removal is declarative: drop the entry, run a rebuild), renders per-plugin
  `settings` to `plugins/config/<id>/config.toml`, and verifies each declared
  root produced a registry entry. No Go toolchain and no network are needed on
  the host — unlike `herdr plugin install`, which clones from GitHub and runs
  the manifest `[[build]]`. `herdr plugin install` entries and checkout links
  are never pruned (only link-installed `/nix/store` roots are).

  The bare-package entry works because the plugin flake ships
  `passthru.herdrPluginId`; not-Nix-aware plugins use `{ pluginId; package; }`
  or `{ path = …; }` (id resolved from the registry after linking). Plugin
  **keybindings** still live in the live-linked `config.toml`; the sidebar
  jump popup binds `herdr-preview-grid jump` by name — the manager's
  `addPluginBinsToPath` (default on) puts each plugin package's `bin` on
  `home.sessionPath`. Note activation itself uses ABSOLUTE binary paths:
  HM activation runs with a restricted PATH (stateVersion ≥ 22.11 default)
  where `command -v herdr` fails.

  Dev iteration conflicts with activation (each rebuild re-links the store
  path): set `programs.herdr-hpm.plugins` to `[{ path = ~/src/herdr-vimnav; }]`
  while hacking on a plugin, or drop the entry and link the checkout by hand.
- **OpenClaw**: Provided by the first-party `nix-openclaw` flake input (official openclaw org) — **never add `pkgs.openclaw` to any package list**: nixpkgs' own package is permanently marked insecure (LLM prompt-injection policy flag, not a CVE — no fix without `permittedInsecurePackages`, which is off-limits by project rule). The host applies `inputs.nix-openclaw.overlays.default` to pkgs; the full HM module lives in **nixconf-private** (`homeManagerModules.openclaw`, imported in the host's HM module list, gated by `myconf.openclaw.enable` — personal data stays private). It configures the OpenCode Go model backend (`opencode-go/glm-5.3-flash`; bundled provider, `enabledByDefault` in the pinned 2026.9.5 package — no plugin install needed), the Telegram channel (pairing DM policy, `richMessages` = Bot API 10.3 rich blocks), and gateway autostart. The gateway runs in Nix mode (config immutable; manage via `programs.openclaw.config` in nixconf-private + rebuild — `openclaw onboard`/`plugins install` are disabled). Secrets are plain 600 files at `~/.secrets/openclaw/` (`opencode-api-key`, `telegram-bot-token`, `gateway-token`), referenced by path — never inline secrets in Nix. nixconf-private's own `nix-openclaw` input is deduped to the top-level one via `inputs.nix-openclaw.follows` (single lock entry).

- **ChatGPT**: Packaging and the gated Home Manager module live in `nixconf-private` (`overlays.chatgpt`, `homeManagerModules.chatgpt`), following OpenPets. Both desktop hosts apply the overlay and import the module; `myconf.chatgpt.enable` enables the app. The pet window title patch and the matching Hyprland Lua rule belong to the private app files.

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

