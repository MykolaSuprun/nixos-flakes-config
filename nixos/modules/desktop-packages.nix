{
  pkgs,
  pkgs-stable,
  ...
}: {
  programs = {
    steam = {
      enable = true;
    };
    gamemode = {
      enable = true;
      enableRenice = true;
    };
    kdeconnect.enable = true;
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    firefox = {
      enable = true;
      package = pkgs.firefox;
      # preferences = {
      #   "widget.use-xdg-desktop-portal.file-picker" = 1;
      # };
    };
  };

  environment.systemPackages = with pkgs; [
    steam-run

    veracrypt

    # QT and GTK themes
    plasma-overdose-kde-theme
    materia-kde-theme
    graphite-kde-theme
    arc-kde-theme
    adapta-kde-theme
    fluent-gtk-theme
    adapta-gtk-theme
    mojave-gtk-theme
    numix-gtk-theme
    whitesur-kde
    whitesur-gtk-theme
    whitesur-icon-theme
    whitesur-cursors
    catppuccin
    catppuccin-kde
    catppuccin-gtk
    catppuccin-qt5ct
    catppuccin-kvantum
    catppuccin-cursors
    catppuccin-papirus-folders

    # sddm theme
    catppuccin-sddm-corners
  ];
}
