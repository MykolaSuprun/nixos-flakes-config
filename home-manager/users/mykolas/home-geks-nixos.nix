# Home-manager configuration for mykolas on geks-nixos (AMD desktop, Hyprland).
# HM feature modules (home-manager/modules/*.nix) are auto-imported by import-tree
# in the host's default.nix; enable flags below activate them.
{
  config,
  inputs,
  pkgs,
  ...
}: {
  # ── Feature-module enable flags ──────────────────────────────────────────────
  myconf = {
    shell.enable = true;
    dev.enable = true;
    desktop.enable = true;
    chromium.enable = true;
    dms.enable = true;
    # noctalia.enable = true;
    catppuccin.enable = true;
    ghostty.enable = true;
    rofi.enable = true;
    fcitx5.enable = true;
    # zellij.enable = false;
    # flatpakOverrides.enable = false;
  };

  hyprconf = {
    waybar = {
      enable = true;
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
      };
    };
  };

  services.gpg-agent = {
    enable = true;
    grabKeyboardAndMouse = true;
    pinentry.package = pkgs.pinentry-tty;
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
    "./.config/clipse" = {
      source = ./config/clipse;
      recursive = true;
    };
    "./.config/freerdp/sdl-freerdp.json".source = ./config/freerdp/sdl-freerdp.json;
    "./.gitconfig".source = ./config/gitconfig/gitconfig;
    # Default terminal for xdg-terminal-exec (read by DMS Default Apps settings)
    ".config/xdg-terminals.list".text = "com.mitchellh.ghostty.desktop\n";
    "./.gnupg/" = {
      source = ./config/gnupg;
      recursive = true;
    };
  };

  home.packages = with pkgs; [];
}
