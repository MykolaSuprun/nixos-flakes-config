{
  config,
  lib,
  pkgs,
  ...
}: {
  # Read the changelog before changing this value
  home.stateVersion = "24.05";

  imports = [
    ./../../modules/geks-nix-on-droid.nix
  ];

  # insert home-manager config

  home.packages = with pkgs; [
    jetbrains-mono
    noto-fonts
    liberation_ttf
    dejavu_fonts
  ];
  home.file = {
    "./.gitconfig".source = ./gitconfig/gitconfig;
  };

  fonts.fontconfig.enable = true;
}
