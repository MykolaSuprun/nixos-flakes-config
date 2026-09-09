# Home-manager configuration for mykolas on geks-nixos (AMD desktop, Hyprland).
# HM feature modules (home-manager/modules/*.nix) are auto-imported by import-tree
# in the host's default.nix; enable flags below activate them.
{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: let
  steam-gamescope = pkgs.writeShellScriptBin "steam-gamescope" ''
    export DXVK_HDR=1
    export ENABLE_GAMESCOPE_WSI=1
    exec ${pkgs.gamescope}/bin/gamescope \
      --adaptive-sync \
      --hdr-enabled \
      --hdr-itm-enable \
      --rt \
      --mangoapp \
      --force-grab-cursor \
      --steam \
      --xwayland-count 2 \
      --expose-wayland \
      --prefer-vk-device 1002:744c \
      -W 3440 -H 1440 \
      -r 165 \
      -f \
      -- ${pkgs.steam}/bin/steam -gamepadui -steamos
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
    # zellij.enable = false;
    # flatpakOverrides.enable = false;
        herdr.enable = true;
    audio-recovery.enable = true; # restart audio stack after resume (xHCI reinit wedges it)
  };

  programs.noctalia.enable = true; # v5 Noctalia shell (built-in default settings)

    hyprconf = {
    target = "geks-nixos";
    noctalia.enable = true;
    waybar = {
      enable = false;
      output = null;
    };
    hyprland = {
      enable = true;
      flake.enable = true;
    };
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
    DEFAULT_BROWSER = "$(which zen-beta)";
    BROWSER = "$(which zen-beta)";
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
