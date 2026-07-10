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
    # Git config is now managed via myconf.git.enable in the geks-nix-on-droid module
  };

  fonts.fontconfig.enable = true;
}
