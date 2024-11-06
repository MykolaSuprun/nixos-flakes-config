{pkgs, ...}: {
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      plasma6Support = true;
      addons = with pkgs; [
        fcitx5-rime
        fcitx5-gtk
        kdePackages.fcitx5-with-addons
        kdePackages.fcitx5-qt
        kdePackages.fcitx5-configtool
        libsForQt5.fcitx5-qt
        fcitx5-chinese-addons
        fcitx5-table-other
        fcitx5-hangul
        fcitx5-unikey
        fcitx5-m17n
        fcitx5-mozc
        fcitx5-lua
      ];
    };
  };
}
