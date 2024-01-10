{pkgs, pkgs-stable, ...}: {

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
  };

  home.packages = with pkgs; [
    # plasma packages and basic applications
    # libsForQt5.sddm-kcm
    # libsForQt5.ark
    # libsForQt5.yakuake
    # libsForQt5.qmltermwidget
    # libsForQt5.qt5.qtwebsockets
    # libsForQt5.qtstyleplugin-kvantum # flatpak plasma theming compatibility tool
    # libsForQt5.kpmcore
    # libsForQt5.plasma-browser-integration
    # libsForQt5.dolphin-plugins

    # internet
    mullvad-browser
    protonvpn-gui


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
    partition-manager
    obsidian
    calibre

    # virtualization
    distrobox

    # theming
    papirus-icon-theme
    # catppuccin-papirus-folders
    catppuccin-kde
    catppuccin-gtk
    catppuccin-kvantum
    catppuccin-cursors

    # wine, steam and other gaming related packages
    steam
    mesa
    libdrm
    wine-staging
    winetricks
    vulkan-tools
    vulkan-loader
    vulkan-extension-layer
    vkBasalt
    dxvk
    vulkan-headers
    vulkan-validation-layers
    wine64Packages.fonts
    winePackages.fonts
    gamescope
    mangohud

    # media
    spotify
    vlc
    cider
  ];
}
