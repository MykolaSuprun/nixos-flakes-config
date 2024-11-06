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
    # kdePackages.sddm-kcm
    kdePackages.ark
    kdePackages.yakuake
    kdePackages.dolphin
    libsForQt5.kservice
    kdePackages.kservice

    # internet
    mullvad-browser
    protonvpn-gui
    lbry

    # social
    discord
    signal-desktop
    telegram-desktop

    # other
    megasync
    pkgs-stable.cryptomator
    qbittorrent
    morgen
    libreoffice-qt
    ledger-live-desktop
    protonup-qt
    protonup-ng
    ldacbt

    obsidian

    # virtualization
    distrobox
    docker-compose

    # wine, steam and other gaming related packages
    bottles

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
    freerdp3
    gtk-frdp
  ];
}
