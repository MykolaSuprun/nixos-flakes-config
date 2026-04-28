{
  inputs,
  lib,
  config,
  ...
}: {
  options.myconf.flatpakOverrides.enable = lib.mkEnableOption "Flatpak environment overrides";
  config = lib.mkIf config.myconf.flatpakOverrides.enable {
    home.file.".local/share/flatpak/overrides/global".text = ''

      [Context]
      filesystems=xdg-config/Kvantum:ro;~/.themes:ro;~/.local/share/icons:ro;~/.local/share/fonts:ro;/usr/share/icons:ro;/usr/share/fonts;

      [Environment]
      QT_STYLE_OVERRIDE=kvantum
      QT_QPA_PLATFORMTHEME=WhiteSur-Light-solid
      GTK_THEME=WhiteSur-Light-solid
      ICON_THEME=WhiteSur
    '';
  };
}
