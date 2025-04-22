{
  inputs,
  pkgs,
  ...
}: {
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
    NH_FLAKE = "/home/mykolas/.nixconf";
    BROWSER = "${inputs.zen-browser.packages.${pkgs.system}.default}/bin/zen";
    DEFAULT_BROWSER = "${inputs.zen-browser.packages.${pkgs.system}.default}/bin/zen";
  };
}
