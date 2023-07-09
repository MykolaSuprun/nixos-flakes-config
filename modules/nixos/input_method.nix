{ inputs, pkgs, ... }: {
  i18n.inputMethod = {
    # enabled = "ibus";
    # ibus.engines = with pkgs.ibus-engines; [ 
    #   hangul
    #   m17n
    #   mozc
    #   rime
    #   table
    #   table-chinese
    #   table-others
    #   typing-booster uniemoji
    # ];

    enabled = "fcitx5";

    fcitx5.addons = with pkgs; [
      fcitx5-with-addons
      fcitx5-rime
      fcitx5-gtk
      libsForQt5.fcitx5-qt
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
