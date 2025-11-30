{
  config,
  pkgs,
  ...
}: {
  # fix for flatpak fonts and cursor/icon themes
  system.fsPackages = [pkgs.bindfs];

  fileSystems = let
    mkRoSymBind = path: {
      device = path;
      fsType = "fuse.bindfs";
      options = ["ro" "resolve-symlinks" "x-gvfs-hide"];
    };
    aggregated = pkgs.buildEnv {
      name = "system-fonts-and-icons";
      paths =
        config.fonts.packages
        ++ (with pkgs; [
          # Add your cursor themes and icon packages here
          # Cursors
          bibata-cursors
          catppuccin-cursors.mochaMauve # or .lattePink, .frappeLavender, etc.

          # GTK themes
          gnome.gnome-themes-extra
          catppuccin-gtk

          # Icon themes
          papirus-icon-theme
          catppuccin-papirus-folders.catppuccin-latte # Available variants: latte, frappe, macchiato, mocha
        ]);
      pathsToLink = ["/share/fonts" "/share/icons"];
      ignoreCollisions = true; # Add this parameter
    };
  in {
    "/usr/share/fonts" = mkRoSymBind "${aggregated}/share/fonts";
    "/usr/share/icons" = mkRoSymBind "${aggregated}/share/icons";
  };
}
