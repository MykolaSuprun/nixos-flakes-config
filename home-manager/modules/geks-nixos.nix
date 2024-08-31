{
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
    ./input_method.nix
    ./shell.nix
    # ./chromium.nix
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
  };
}
