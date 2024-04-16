{
  pkgs,
  pkgs-stable,
  ...
}: {
  xdg = {
    enable = true;
  };

  home.packages = with pkgs; [
    # plasma packages and basic applications
    kdePackages.sddm-kcm
    kdePackages.ark
    kdePackages.yakuake
    kdePackages.qtstyleplugin-kvantum
    kdePackages.qtwebsockets
    kdePackages.qtstyleplugin-kvantum
    kdePackages.plasma-browser-integration
    kdePackages.dolphin-plugins
    kdePackages.kfind
    kdePackages.kimageformats
    kdePackages.qtimageformats

    # internet
    mullvad-browser
    pkgs-stable.protonvpn-gui

    # social
    discord
    signal-desktop
    telegram-desktop

    # other
    megasync
    qbittorrent
    morgen
    tusk
    libreoffice-qt
    ledger-live-desktop
    calibre
    protonup-qt

    obsidian

    # virtualization
    distrobox

    # theming
    # catppuccin-papirus-folders
    # catppuccin-kde
    # catppuccin-gtk
    # catppuccin-kvantum
    # catppuccin-cursors
    # ayu-theme-gtk

    # wine, steam and other gaming related packages
    bottles

    # media
    pkgs-stable.spotify
    vlc
    cider

    # gaming
    # steamtinkerlaunch dependencies
    xdotool
    xorg.xwininfo
    yad
    unzip
    unixtools.xxd
  ];
}
