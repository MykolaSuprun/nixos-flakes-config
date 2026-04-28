{pkgs, lib, config, ...}: {
  options.myconf.fcitx5.enable = lib.mkEnableOption "Fcitx5 input method";
  config = lib.mkIf config.myconf.fcitx5.enable {
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [
        fcitx5-rime
        fcitx5-gtk
        kdePackages.fcitx5-with-addons
        kdePackages.fcitx5-qt
        kdePackages.fcitx5-configtool
        libsForQt5.fcitx5-qt
        qt6Packages.fcitx5-chinese-addons
        fcitx5-table-other
        fcitx5-hangul
        qt6Packages.fcitx5-unikey
        fcitx5-m17n
        fcitx5-mozc
        fcitx5-lua
      ];
    };
  };
  };
}
