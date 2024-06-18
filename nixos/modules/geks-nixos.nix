{
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
    ./xdg.nix
    ./nix-conf.nix
    ./fonts.nix
    ./pipewire.nix
    ./sys-pkgs.nix
    ./desktop-config.nix
    ./catppuccin.nix
    ./hyprland.nix
  ];
}
