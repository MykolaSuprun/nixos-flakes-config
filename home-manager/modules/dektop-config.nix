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

    # internet
    mullvad-browser
    (vivaldi.overrideAttrs (old: {
      buildInputs =
        (old.buildInputs or [])
        ++ [
          libsForQt5.qtwayland
          libsForQt5.qtx11extras
          kdePackages.plasma-integration.qt5
          kdePackages.kio-extras-kf5
          kdePackages.breeze.qt5
          vivaldi-ffmpeg-codecs
        ];
    }))
    vivaldi-ffmpeg-codecs
    protonvpn-gui
    lbry

    # social
    discord
    signal-desktop
    telegram-desktop

    # other
    pkgs-stable.megasync
    cryptomator
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
    bemenu
  ];
}
