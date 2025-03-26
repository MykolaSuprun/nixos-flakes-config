{
  inputs,
  pkgs,
  pkgs-stable,
  ...
}: {
  xdg = {enable = true;};

  home.packages = with pkgs; [
    # plasma packages and basic applications
    # kdePackages.sddm-kcm
    kdePackages.ark
    kdePackages.yakuake
    kdePackages.dolphin
    libsForQt5.kservice
    kdePackages.kservice
    kdePackages.qtstyleplugin-kvantum

    # internet
    mullvad-browser
    inputs.zen-browser.packages.${pkgs.system}.default
    vivaldi
    vivaldi-ffmpeg-codecs
    protonvpn-gui
    lbry

    # social
    discord
    signal-desktop
    telegram-desktop

    # other
    onlyoffice-desktopeditors
    bluetui
    pkgs-stable.megasync
    cryptomator
    qbittorrent
    libreoffice-qt
    ledger-live-desktop
    protonup-qt
    protonup-ng
    ldacbt
    spotify-player
    tidal-hifi

    obsidian

    # virtualization
    distrobox
    docker-compose

    # wine, steam and other gaming related packages
    # bottles
    mangohud

    # media
    spotify
    vlc
    cider

    # gaming
    # steamtinkerlaunch dependencies
    xdotool
    xorg.xwininfo
    yad
    unzip
    unixtools.xxd
    bemenu
    pkgs.freerdp3
    pkgs-stable.gtk-frdp
  ];
}
