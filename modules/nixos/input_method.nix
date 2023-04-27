{inputs, pkgs, ... }: {

  i18n.inputMethod = {
    enabled = "fcitx5";
    # fcitx.engines = with pkgs.fcitx-engines; [
    #   mozc
    #   hangul
    #   m17n
    #   unikey
    #   table-other
    #   rime
    # ];
    fcitx5.addons = with pkgs; [
      fcitx5-rime
      fcitx5-gtk
      libsForQt5.fcitx5-qt
      fcitx5-with-addons
      fcitx5-chinese-addons
      fcitx5-table-other
      fcitx5-configtool
      fcitx5-hangul
      fcitx5-unikey
      fcitx5-m17n
      fcitx5-mozc
      fcitx5-lua
    ];
  };
}