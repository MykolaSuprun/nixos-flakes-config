{
  inputs,
  pkgs,
  pkgs-stable,
  ...
}: {
  xdg = {
    enable = true;
  };

  programs.zen-browser.enable = true;

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
    pkgs-stable.protonvpn-gui
    lbry
    vivaldi
    filen-desktop
    impala # tui wifi manager

    # social
    discord
    signal-desktop
    telegram-desktop
    tg

    # other
    onlyoffice-desktopeditors
    bluetui
    pkgs-stable.megasync
    cryptomator
    qbittorrent
    libreoffice-qt
    ledger-live-desktop
    protonup-qt
    protonplus
    protonup-ng
    ldacbt
    spotify-player
    ffmpeg-full

    obsidian
    basalt

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
    limo
    # steamtinkerlaunch dependencies
    xdotool
    xorg.xwininfo
    yad
    unzip
    unixtools.xxd
    bemenu
    pkgs.freerdp
    pkgs-stable.gtk-frdp
  ];
}
