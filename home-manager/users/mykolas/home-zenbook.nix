# Home-manager configuration for mykolas on geks-zenbook (Intel laptop, Hyprland).
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
    noctalia.enable = true;
    catppuccin.enable = true;
    rofi.enable = true;
    fcitx5.enable = true;
    # zellij.enable = false;
    # flatpakOverrides.enable = false;
  };

  hyprconf = {
    target = "geks-zenbook";
    monitorsConf = "geks-zenbook-monitors.conf";
    waybar = {
      enable = true;
      output = ["DP-1"];
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
    NIXOS_TARGET = "geks-zenbook";
    BEMENU_BACKEND = "wayland";
    BROWSER = "${inputs.zen-browser.packages.${pkgs.system}.beta}/bin/zen";
    DEFAULT_BROWSER = "${inputs.zen-browser.packages.${pkgs.system}.beta}/bin/zen";
  };

  # ── User identity ─────────────────────────────────────────────────────────────
  home.username = "mykolas";
  home.homeDirectory = "/home/mykolas";
  home.stateVersion = "25.05";

  xdg = {enable = true;};

  services.gpg-agent = {
    enable = true;
    grabKeyboardAndMouse = true;
    pinentry.package = pkgs.pinentry-tty;
  };

  programs.home-manager.enable = true;

  dconf.settings = {};

  # ── Dotfile symlinks ──────────────────────────────────────────────────────────
  home.file = {
    "./.config/autostart" = {
      source = ./config/autostart;
      recursive = true;
    };
    "./.gitconfig".source = ./config/gitconfig/gitconfig;
    "./.gnupg/" = {
      source = ./config/gnupg;
      recursive = true;
    };
  };

  home.packages = with pkgs; [];
}
