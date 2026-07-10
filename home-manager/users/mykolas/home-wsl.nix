# Home-manager configuration for mykolas on geks-wsl (minimal, no GUI).
# HM feature modules (home-manager/modules/*.nix) are auto-imported by import-tree
# in the host's default.nix; enable flags below activate them.
{
  config,
  pkgs,
  pkgs-stable,
  ...
}: {
  # ── Feature-module enable flags ──────────────────────────────────────────────
  myconf = {
    shell.enable = true;
    ssh.enable = true;
    dev.enable = true;
    git.enable = true;
    catppuccin.enable = true;
    helix.enable = true;
    tmux.enable = true;
  };

  # ── Session variables ─────────────────────────────────────────────────────────
  home.sessionVariables = {
    NIXOS_CONF_DIR = "$HOME/.nixconf";
    NIXOS_TARGET = "geks-wsl";
    NH_FLAKE = "/home/mykolas/.nixconf";
  };

  # ── User identity ─────────────────────────────────────────────────────────────
  home.username = "mykolas";
  home.homeDirectory = "/home/mykolas";
  home.stateVersion = "23.11";

  xdg = {enable = true;};

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    grabKeyboardAndMouse = true;
    pinentry.package = pkgs.pinentry-tty;
    defaultCacheTtl = 86400; # 24 hours
    defaultCacheTtlSsh = 86400; # 24 hours
    maxCacheTtl = 604800; # 7 days
    maxCacheTtlSsh = 604800; # 7 days
    # Allow TTY-based passphrase prompts when no display is available.
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };

  programs.home-manager.enable = true;

  # ── Dotfile symlinks ──────────────────────────────────────────────────────────
  home.file = {
    "./.gnupg/" = {
      source = ./config/gnupg;
      recursive = true;
    };
  };

  home.packages = with pkgs; [];
}
