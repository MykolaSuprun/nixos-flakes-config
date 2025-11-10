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
    target = "geks-zenbook";
    hyprland = {
      enable = true;
    };
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
    NIXOS_CONF_DIR = "$HOME/workspaces/src/nixconf";
    NH_FLAKE = "$HOME/workspaces/src/nixconf";
    NIXOS_TARGET = "geks-zenbook";
    BEMENU_BACKEND = "wayland";
    BROWSER = "${inputs.zen-browser.packages.${pkgs.system}.default}/bin/zen";
    DEFAULT_BROWSER = "${inputs.zen-browser.packages.${pkgs.system}.default}/bin/zen";
  };
}
