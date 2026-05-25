{
  inputs,
  pkgs,
  pkgs-stable,
  lib,
  config,
  ...
}: {
  options.myconf.desktop.enable = lib.mkEnableOption "desktop apps";
  config = lib.mkIf config.myconf.desktop.enable {
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
      kdePackages.kservice
      kdePackages.qtstyleplugin-kvantum
      krusader
      #krusader dependencies
      xxdiff
      kdiff3
      krename
      kdePackages.okular
      kdePackages.gwenview
      kdePackages.kde-cli-tools
      kdePackages.kio-extras
      pkgs-stable.zoom-us

      nemo-with-extensions

      clipse
      pkgs.kdePackages.qttools
      krita-unwrapped

      # icon themes
      catppuccin-papirus-folders

      # internet
      mullvad-browser
      proton-vpn
      lbry
      vivaldi
      floorp-bin
      filen-desktop
      impala # tui wifi manager

      # social
      discord
      signal-desktop
      ayugram-desktop
      telegram-desktop
      viber
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
      gimp
      vlc
      cider-2

      # gaming
      pkgs-stable.limo
      umu-launcher
      # steamtinkerlaunch dependencies
      xdotool
      xwininfo
      yad
      unzip
      unixtools.xxd
      bemenu
      pkgs.freerdp
      pkgs-stable.gtk-frdp
    ];
  };
}
