# Home Manager configuration for mykolas on geks-nixos (AMD desktop).
# Shared user settings: modules/users/mykolas.nix.
{inputs, ...}: {
  configurations.nixos.geks-nixos.home = {
    pkgs,
    lib,
    ...
  }: let
    gamingGpuId = "1002:744c"; # RX 7900 XTX
    gamingGpuEnv = ''
      export DRI_PRIME=${lib.escapeShellArg gamingGpuId}
      export MESA_VK_DEVICE_SELECT=${lib.escapeShellArg "${gamingGpuId}!"}
    '';
    steam-dgpu = pkgs.writeShellScript "steam-dgpu" ''
      ${gamingGpuEnv}
      exec ${pkgs.steam}/bin/steam "$@"
    '';
    # NOTE (2026-09-11): --mangoapp REMOVED — mangoapp 0.8.4 is X11-only and
    # segfaults (XInternAtom on NULL Display) under gamescope --expose-wayland;
    # gamescope's reaper respawns it ~1/sec (96k coredumps/day observed).
    steam-gamescope = let
      gamescopeArgs = [
        "--adaptive-sync"
        "--hdr-enabled"
        "--hdr-itm-enable"
        "--rt"
        "--force-grab-cursor"
        "--steam"
        "--xwayland-count"
        "2"
        "--expose-wayland"
        "--prefer-vk-device"
        gamingGpuId
        "-W"
        "3440"
        "-H"
        "1440"
        "-r"
        "165"
        "-f"
      ];
    in
      pkgs.writeShellScriptBin "steam-gamescope" ''
        ${gamingGpuEnv}
        export DXVK_HDR=1
        export ENABLE_GAMESCOPE_WSI=1
        exec ${pkgs.gamescope}/bin/gamescope ${lib.escapeShellArgs gamescopeArgs} -- ${steam-dgpu}
      '';
  in {
    myconf = {
      shell.enable = true;
      ssh.enable = true;
      dev.enable = true;
      dev.gui.enable = true;
      dev.gpu = "amd";
      git.enable = true;
      nix-index.enable = true;
      desktop.enable = true;
      chromium.enable = true;
      qs-flow.enable = true; # vendored-minflair quickshell shell; owns the lock
      catppuccin.enable = true;
      catppuccin.flavor = lib.mkDefault "latte";
      ghostty.enable = true;
      wezterm.enable = true;
      rofi.enable = true;
      fcitx5.enable = true;
      opencode.enable = true;
      openpets.enable = true;
      openclaw.enable = true;
      chatgpt.enable = true;
      # Strata — local LLM inference engine. The backend matches this host's
      # card (Radeon RX 7900 XT/XTX, gfx1100); the engine is pre-seeded into
      # the components folder so the Terminal can start it.
      strata.enable = true;
      strata.backend = "hip-rx7900";
      strata.clients.enable = true; # OpenCode, Pi and Claude desktop-model connections
      herdr.enable = true;
    };

    services.ai-gateway.enable = true;
    programs.aidev.enable = true;

    # Noctalia shell off (qs-flow replaces it); the input + greeter stay for
    # rollback, and noctalia-greeter still owns the login screen.
    programs.noctalia.enable = false;

    # herdr plugins — declarative via nix-herdr-manager (programs.herdr-hpm):
    # the plugin store paths are linked into herdr's registry at HM activation
    # and undeclared store links are pruned. The bare package entry works because
    # the plugin flake ships passthru.herdrPluginId.
    programs.herdr-hpm = {
      enable = true;
      # Version guard: the plugin manifest declares min_herdr_version; the module
      # asserts it against programs.herdr.package.version at EVAL time. Read from
      # the flake INPUT SOURCE tree (already realized during resolution — not
      # IFD; a store path built from the package would be).
      manifestChecks = ["${inputs.herdr-vimnav}/herdr-plugin.toml"];
      plugins = let
        inherit (pkgs.stdenv.hostPlatform) system;
      in [
        inputs.herdr-vimnav.packages.${system}.default
        inputs.nix-herdr-manager.packages.${system}.herdr-simple-switcher
        inputs.nix-herdr-manager.packages.${system}.herdr-configurable-picker
      ];
    };

    hyprconf = {
      noctalia.enable = false;
      hyprland = {
        enable = true;
        # Mixed-scale AMD outputs exhibit stale hardware cursor shapes.
        softwareCursor = true;
      };
    };

    home.sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
    home.stateVersion = "24.11";

    xdg = {
      desktopEntries.steam = {
        name = "Steam";
        genericName = "Game Store";
        comment = "Steam powered by Gamescope (3440x1440@165 HDR VRR)";
        exec = "${steam-gamescope}/bin/steam-gamescope";
        icon = "steam";
        categories = ["Game"];
        type = "Application";
        terminal = false;
        actions.normal = {
          name = "Launch without Gamescope";
          exec = "${steam-dgpu}";
        };
      };
      configFile = {
        clipse = {
          source = ../../../dotfiles/clipse;
          recursive = true;
        };
        "freerdp/sdl-freerdp.json".source = ../../../dotfiles/freerdp/sdl-freerdp.json;
        # Default terminal for xdg-terminal-exec.
        "xdg-terminals.list".text = "com.mitchellh.ghostty.desktop\n";
      };
    };

    home.packages = [steam-gamescope];
  };
}
