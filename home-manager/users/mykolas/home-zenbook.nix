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
    ssh.enable = true;
    dev.enable = true;
    git.enable = true;
    desktop.enable = true;
    chromium.enable = true;
    noctalia.enable = true;
    noctalia.barMonitors = ["DP-1"];
    catppuccin.enable = true;
    catppuccin.flavor = "mocha";
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
  };

  hyprconf = {
    target = "geks-zenbook";
    noctalia.enable = true;
    waybar = {
      enable = true;
      output = ["DP-1"];
    };
    hyprland = {
      enable = true;
      flake.enable = true;
    };
    hypridle.oledOptimized = true;
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

  dconf.settings = {};

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
    "./.gnupg/" = {
      source = ./config/gnupg;
      recursive = true;
    };
  };

  home.packages = with pkgs; [];
}
