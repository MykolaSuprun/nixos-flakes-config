{pkgs, ...}: {
  imports = [
    ./shell.nix
    ./chromium.nix
    # ./fcitx5.nix
    # ./flatpak-overrides.nix
    ./tmux.nix
    # ./zellij.nix
    ./dev-pkgs.nix
    ./dektop-config.nix
    ./catppuccin.nix
    ./hyprland.nix
    ./waybar.nix
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
    NIXOS_CONF_DIR = "$HOME/.nixconf";
    NIXOS_TARGET = "geks-nixos";
    BEMENU_BACKEND = "wayland";
    FLAKE = "/home/mykolas/.nixconf";
    BROWSER = "${pkgs.firefox}/bin/firefox";
    DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
    IGPU = "pci-0000_59_00_0";
    DGPU = "pci-0000_03_00_0";
    DRI_PRIME = "pci-0000_03_00_0";
  };
}
