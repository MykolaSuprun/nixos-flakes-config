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
    ./desktop-pkgs.nix
    ./catppuccin.nix
  ];
}
