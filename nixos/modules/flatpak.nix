{ config, pkgs, ... }: {
  # fix for flatpak fonts and cursor/icon themes
  system.fsPackages = [ pkgs.bindfs ];

  fileSystems = let
    mkRoSymBind = path: {
      device = path;
      fsType = "fuse.bindfs";
      options = [ "ro" "resolve-symlinks" "x-gvfs-hide" ];
    };
    aggregated = pkgs.buildEnv {
      name = "system-fonts-and-icons";
      paths = config.fonts.packages ++ (with pkgs; [
        # Add your cursor themes and icon packages here
        catppuccin-cursors
        catppuccin-papirus-folders
        # etc.
      ]);
      pathsToLink = [ "/share/fonts" "/share/icons" ];
    };
  in {
    "/usr/share/fonts" = mkRoSymBind "${aggregated}/share/fonts";
    "/usr/share/icons" = mkRoSymBind "${aggregated}/share/icons";
  };
}
