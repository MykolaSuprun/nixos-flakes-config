# Flake-parts host module for geks-nixos (AMD desktop, Hyprland + gaming).
# NixOS feature modules (nixos/*.nix) and HM feature modules
# (home-manager/modules/*.nix) are all imported here; each is gated by its
# own myconf.* / hyprconf.* enable flag set in configuration.nix / home-geks-nixos.nix.
{
  inputs,
  withSystem,
  ...
}: let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;

    # overlays/opencode.nix supplies pkgs.opencode (V2 from the npm prebuilt,
    # shadowing nixpkgs' broken V1 build); the former nixpkgs-opencode-pin
    # pin overlay was retired together with V1 on 2026-09-29.
    overlays = import ../../../overlays ++ [
      inputs.nixconf-private.overlays.lmstudio
      # OpenPets packages (desktop AppImage repack, MCP bridge, wayland
      # helper, opencode V2 plugin) — moved to nixconf-private 2026-10-14.
      inputs.nixconf-private.overlays.openpets
      inputs.nixconf-private.overlays.chatgpt
      inputs.nixconf-private.overlays.strata
      # First-party OpenClaw (HM module lives in nixconf-private:
      # homeManagerModules.openclaw): nixpkgs' own openclaw stays marked
      # insecure; this overlay supplies the upstream-maintained package the
      # HM module consumes.
      inputs.nix-openclaw.overlays.default
    ];
  };
  pkgs-stable = import inputs.nixpkgs-stable {
    inherit system;
    config.allowUnfree = true;
    # winboat (from pkgs-stable) pulls stable's electron-40.10.5, which
    # nixpkgs marks insecure (upstream Signal-style Electron window). Scope:
    # pkgs-stable only — the main pkgs instance needs NO exemption.
    # Drop when winboat's stable Electron advances past the insecure window.
    config.permittedInsecurePackages = ["electron-40.10.5"];
  };
  lib = inputs.nixpkgs.lib;
  useHyprlandFlake = true;
  wrappedPkgs = withSystem system ({config, ...}: config.packages);
in {
  flake.nixosConfigurations.geks-nixos = lib.nixosSystem {
    inherit system pkgs;
    modules =
      [
        inputs.determinate.nixosModules.default
        inputs.catppuccin.nixosModules.catppuccin
        inputs.stylix.nixosModules.stylix
        inputs.noctalia-greeter.nixosModules.default
        inputs.disko.nixosModules.disko
        ./_disk-config.nix
        ./_hardware.nix
        ./_configuration.nix
        # NixOS feature modules (all gated by myconf.nixos.*.enable flags)
        ../../../nixos/bees.nix
        ../../../nixos/catppuccin.nix
        ../../../nixos/desktop-config.nix
        ../../../nixos/flatpak.nix
        ../../../nixos/fonts.nix
        ../../../nixos/hyprland.nix
        ../../../nixos/lianli.nix
        ../../../nixos/nix-conf.nix
        ../../../nixos/pipewire.nix
        ../../../nixos/secrets.nix
        ../../../nixos/sys-pkgs.nix
        ../../../nixos/stylix.nix
        ../../../nixos/xdg.nix
        # Private AI stack (nixconf-private flake input): local LLM
        # (ollama + open-webui) + ComfyUI (clean default install on :8188
        # via the utensils/comfyui-nix flake, prebuilt ROCm wheels).
        # Rebuild as the user with --use-remote-sudo.
        inputs.nixconf-private.nixosModules.llm
        inputs.nixconf-private.nixosModules.comfyui
        ../../../nixos/moshi-hook.nix
        ../../../nixos/specialisations.nix
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-back";
            users.mykolas = {
              imports =
                [
                  inputs.catppuccin.homeModules.catppuccin
                  inputs.zen-browser.homeModules.beta
                  inputs.dms.homeModules.dank-material-shell
                  inputs.dms-plugin-registry.nixosModules.default
                  inputs.caelestia-shell.homeManagerModules.default
                  inputs.qs-flow.homeManagerModules.default
                  inputs.nix-herdr-manager.homeManagerModules.default

                  ../../../home-manager/users/mykolas/home-geks-nixos.nix
                  # HM feature modules (all gated by myconf.*.enable flags)
                  ../../../home-manager/modules/audio-recovery.nix
                  ../../../home-manager/modules/caelestia.nix
                  ../../../home-manager/modules/catppuccin.nix
                  ../../../home-manager/modules/dms.nix
                  ../../../home-manager/modules/qs-flow.nix
                  ../../../home-manager/modules/chromium.nix
                  ../../../home-manager/modules/desktop-config.nix
                  ../../../home-manager/modules/dev-pkgs.nix
                  # Private LLM tooling (llama-cpp-rocm + comfy-ui CLI from
                  # the utensils/comfyui-nix flake, prebuilt ROCm wheels)
                  inputs.nixconf-private.homeManagerModules.llm-tools
                  ../../../home-manager/modules/fcitx5.nix
                  ../../../home-manager/modules/git.nix
                  ../../../home-manager/modules/ghostty.nix
                  ../../../home-manager/modules/helix.nix
                  ../../../home-manager/modules/herdr.nix
                  ../../../home-manager/modules/kitty.nix
                  ../../../home-manager/modules/rofi.nix
                  ../../../home-manager/modules/shell.nix
                  ../../../home-manager/modules/ssh.nix
                  ../../../home-manager/modules/stylix.nix
                  ../../../home-manager/modules/tmux.nix
                  ../../../home-manager/modules/waybar.nix
                  ../../../home-manager/modules/wezterm.nix
                  ../../../home-manager/modules/zellij.nix
                  ../../../home-manager/modules/opencode.nix
                  # OpenPets: module lives in nixconf-private (moved
                  # 2026-10-14, openclaw precedent) — needs that flake's
                  # overlays.openpets for pkgs.openpets*.
                  inputs.nixconf-private.homeManagerModules.openpets
                  inputs.nixconf-private.homeManagerModules.chatgpt
                  # Strata packaging and client launchers live in the private
                  # input; overlays.strata supplies the backend packages.
                  inputs.nixconf-private.homeManagerModules.strata
                  # OpenClaw: full module (config, secrets wiring, autostart)
                  # lives in nixconf-private — personal data stays private.
                  inputs.nixconf-private.homeManagerModules.openclaw
                  # llm-help: interactive picker for the ai-profiles
                  # Claude Code / pi launchers. Nix owns only the tool; the
                  # profile table + keys stay plain files under
                  # ~/.config/ai-profiles (user decision 2026-10-20).
                  inputs.nixconf-private.homeManagerModules.llm-help
                  ../../../home-manager/modules/hyprland
                ]
                ++ lib.optionals useHyprlandFlake [
                  inputs.hyprland.homeManagerModules.default
                ];
              home.packages = [
                wrappedPkgs.nix-update
                wrappedPkgs.hypr-layout-picker
                wrappedPkgs.specialisation-picker
                wrappedPkgs."opencode-lmstudio-sync"
              ];
            };
            extraSpecialArgs = {
              inherit inputs system pkgs-stable useHyprlandFlake wrappedPkgs;
              outputs = {};
            };
          };
        }
      ]
      ++ lib.optionals useHyprlandFlake [
        inputs.hyprland.nixosModules.default
      ];
    specialArgs = {
      inherit inputs pkgs-stable useHyprlandFlake wrappedPkgs;
      outputs = {};
    };
  };
}
