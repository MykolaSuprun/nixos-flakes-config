{
  pkgs,
  lib,
  config,
  ...
}: {
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

        settings = {
          # Global hotkeys → ~/.config/fcitx5/config
          globalOptions = {
            # Ctrl+Shift+Space: toggle fcitx5 on/off (free: tmux=Ctrl+Space, launcher=Alt+Space)
            Hotkey = {
              TriggerKeys = "Control+Shift+space";
              # Ctrl+Alt+Space: cycle to next input method
              EnumerateForwardKeys = "Control+Alt+space";
            };
            "Hotkey/TriggerKeys" = {
              "0" = "Control+Shift+space";
            };
            "Hotkey/EnumerateForwardKeys" = {
              "0" = "Control+Alt+space";
            };
          };

          # Input method group → ~/.config/fcitx5/profile
          # Order: English, Russian, Polish, Ukrainian, Rime (Chinese), Mozc (Japanese), Hangul (Korean), French
          inputMethod = {
            "Groups/0" = {
              Name = "Default";
              "Default Layout" = "us";
              DefaultIM = "keyboard-us";
            };
            "Groups/0/Items/0" = {Name = "keyboard-us"; Layout = "";};
            "Groups/0/Items/1" = {Name = "keyboard-ru"; Layout = "";};
            "Groups/0/Items/2" = {Name = "keyboard-pl"; Layout = "";};
            "Groups/0/Items/3" = {Name = "keyboard-ua"; Layout = "";};
            "Groups/0/Items/4" = {Name = "rime";        Layout = "";};
            "Groups/0/Items/5" = {Name = "mozc";        Layout = "";};
            "Groups/0/Items/6" = {Name = "hangul";      Layout = "";};
            "Groups/0/Items/7" = {Name = "keyboard-fr"; Layout = "";};
            GroupOrder = {"0" = "0";};
          };

          # Selector addon config — Super+Space opens IM selector popup
          addons.selector = {
            globalSection = {
              TriggerKey = "Super+space";
            };
          };
        };
      };
    };
  };
}
