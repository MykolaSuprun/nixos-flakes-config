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
  };

  environment.systemPackages = with pkgs; [
    steam-run

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
    whitesur-gtk-theme
    whitesur-icon-theme
    # sddm theme
    catppuccin-sddm-corners
  ];
}
