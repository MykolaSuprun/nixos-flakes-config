# Home-manager configuration for mykolas on geks-nixos (AMD desktop, Hyprland).
# HM feature modules (home-manager/modules/*.nix) are hand-listed in the
# host's default.nix (import-tree is NOT used for them); enable flags below
# activate them.
{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: let
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
      "1002:744c"
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
      export DXVK_HDR=1
      export ENABLE_GAMESCOPE_WSI=1
      exec ${pkgs.gamescope}/bin/gamescope ${lib.escapeShellArgs gamescopeArgs} -- ${pkgs.steam}/bin/steam -gamepadui -steamos
    '';
in {
  myconf = {
    shell.enable = true;
    ssh.enable = true;
    dev.enable = true;
    git.enable = true;
    desktop.enable = true;
    chromium.enable = true;
    dms.enable = false; # Noctalia is now the default desktop shell on geks-nixos
    caelestia.enable = false; # Caelestia shell disabled — replaced by custom qs shell (qs-flow); swaylock owns locking
    qs-flow.enable = true; # vendored-minflair quickshell shell: HM install, session autostart, immutable base settings, qs-flow-first lock
    catppuccin.enable = true;
    catppuccin.flavor = lib.mkDefault "latte";
    ghostty.enable = true;
    kitty.enable = true;
    helix.enable = true;
    tmux.enable = true;
    wezterm.enable = true;
    rofi.enable = true;
    fcitx5.enable = true;
    opencode.enable = true;
    openpets.enable = true;
    openclaw.enable = true;
    chatgpt.enable = true;
    herdr.enable = true;
    audio-recovery.enable = true; # restart audio stack after resume (xHCI reinit wedges it)
  };

  # Noctalia off — no desktop shell runs by default right now (custom qs
  # shell in progress). Noctalia input + greeter stay for easy rollback;
  # noctalia-greeter still owns the login screen.
  programs.noctalia.enable = false;

  # herdr plugins — declarative via nix-herdr-manager (programs.herdr-hpm):
  # the plugin store paths are linked into herdr's registry at HM activation
  # and undeclared store links are pruned. The bare package entry works because
  # the plugin flake ships passthru.herdrPluginId.
  programs.herdr-hpm = {
    enable = true;
    plugins = [
      inputs.herdr-vimnav.packages.${pkgs.stdenv.hostPlatform.system}.default
      # Curated upstream plugins (take over the old `herdr plugin install`
      # entries on the next rebuild; delete the orphaned
      # ~/.config/herdr/plugins/github/{simple-switcher,yoshiori}* dirs after).
      inputs.nix-herdr-manager.packages.${pkgs.stdenv.hostPlatform.system}.herdr-simple-switcher
      inputs.nix-herdr-manager.packages.${pkgs.stdenv.hostPlatform.system}.herdr-configurable-picker
    ];
  };

    hyprconf = {
    target = "geks-nixos";
    noctalia.enable = false;
    waybar = {
      enable = false;
      output = null;
    };
    hyprland.enable = true;
  };

  # ── Session variables ─────────────────────────────────────────────────────────
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
    NIXOS_CONF_DIR = "${config.home.homeDirectory}/workspaces/src/nixconf";
    NH_FLAKE = "$HOME/workspaces/src/nixconf";
    APP2UNIT_SLICES = "a=app-graphical.slice b=background-graphical.slice s=session-graphical.slice";
    NIXOS_TARGET = "geks-nixos";
    BEMENU_BACKEND = "wayland";
    BROWSER = "${inputs.zen-browser.packages.${pkgs.system}.beta}/bin/zen";
    DEFAULT_BROWSER = "${inputs.zen-browser.packages.${pkgs.system}.beta}/bin/zen";
  };

  # ── User identity ─────────────────────────────────────────────────────────────
  home.username = "mykolas";
  home.homeDirectory = "/home/mykolas";
  home.stateVersion = "24.11";

  xdg = {
    enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = ["zen-beta.desktop"];
        "x-scheme-handler/http" = ["zen-beta.desktop"];
        "x-scheme-handler/https" = ["zen-beta.desktop"];
        "x-scheme-handler/about" = ["zen-beta.desktop"];
        "x-scheme-handler/unknown" = ["zen-beta.desktop"];
        "image/png" = ["org.kde.gwenview.desktop"];
        "image/jpeg" = ["org.kde.gwenview.desktop"];
        "image/jpg" = ["org.kde.gwenview.desktop"];
        "image/gif" = ["org.kde.gwenview.desktop"];
        "image/bmp" = ["org.kde.gwenview.desktop"];
        "image/webp" = ["org.kde.gwenview.desktop"];
        "image/avif" = ["org.kde.gwenview.desktop"];
        "image/svg+xml" = ["org.kde.gwenview.desktop"];
        "image/tiff" = ["org.kde.gwenview.desktop"];
                "application/pdf" = ["org.kde.okular.desktop"];
                "application/oxps" = ["org.kde.okular.desktop"];
                "application/x-pdf" = ["org.kde.okular.desktop"];
                "application/epub+zip" = ["org.kde.okular.desktop"];
      };
    };
    desktopEntries.steam = {
      name = "Steam";
      genericName = "Game Store";
      comment = "Steam powered by Gamescope (3440x1440@165 HDR VRR)";
      exec = "${steam-gamescope}/bin/steam-gamescope";
      icon = "steam";
      categories = ["Game"];
      type = "Application";
      terminal = false;
      actions = {
        "normal" = {
          name = "Launch without Gamescope";
          exec = "${pkgs.steam}/bin/steam";
        };
      };
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    grabKeyboardAndMouse = true;
    pinentry.package = pkgs.pinentry-qt;
    defaultCacheTtl = 86400; # 24 hours
    defaultCacheTtlSsh = 86400; # 24 hours
    maxCacheTtl = 604800; # 7 days
    maxCacheTtlSsh = 604800; # 7 days
    # Allow TTY-based passphrase prompts when no display is available
    # (e.g. SSH sessions, TTY-only contexts outside UWSM/Hyprland).
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };

  programs.home-manager.enable = true;

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # ── Dotfile symlinks ──────────────────────────────────────────────────────────
  home.file = {
    "./.config/autostart" = {
      source = ./config/autostart;
      recursive = true;
    };
    # KWallet defaults — pre-seeded so the first-ever kwalletd6 prompt (after
    # enabling nixos/secrets.nix) defaults to a blowfish "kdewallet" using the
    # login password, which pam_kwallet_init then auto-unlocks. The apiEnabled
    # line opts kwalletd6 into serving org.freedesktop.secrets on Hyprland.
    "./.config/kwalletrc".text = ''
      [Wallet]
      Enabled=true
      Default Wallet=kdewallet
      First Use=false
      Close When Idle=false

      [org.freedesktop.secrets]
      apiEnabled=true
    '';
    "./.config/clipse" = {
      source = ./config/clipse;
      recursive = true;
    };
    "./.config/freerdp/sdl-freerdp.json".source = ./config/freerdp/sdl-freerdp.json;
    # Default terminal for xdg-terminal-exec (read by DMS Default Apps settings)
    ".config/xdg-terminals.list".text = "com.mitchellh.ghostty.desktop\n";
    "./.gnupg/" = {
      source = ./config/gnupg;
      recursive = true;
    };
  };

  home.packages = [steam-gamescope];
}
