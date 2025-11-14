{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./hyprland
    ./shell.nix
    ./chromium.nix
    ./tmux.nix
    ./kitty.nix
    # ./zellij.nix
    ./dev-pkgs.nix
    ./dektop-config.nix
    # ./stylix.nix
    ./catppuccin.nix
    ./waybar.nix
  ];

  hyprconf = {
    target = "geks-nixos";
    # theme = "catppuccin-latte";
    # accent = "mauve";
    waybar.enable = true;
    hyprland = {
      enable = true;
      flake.enable = true;
    };
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
    NIXOS_CONF_DIR = "$HOME/workspaces/src/nixconf";
    NH_FLAKE = "$HOME/workspaces/src/nixconf";
    NIXOS_TARGET = "geks-nixos";
    BEMENU_BACKEND = "wayland";
    DEFAULT_BROWSER = "$(which zen-beta)";
    BROWSER = "$(which zen-beta)";
  };
}
