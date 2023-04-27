{inputs, ...}: {

    home.file.".local/share/flatpak/overrides/global".text = ''

    [Context]
    filesystems=xdg-config/Kvantum:ro;

    [Environment]
    QT_STYLE_OVERRIDE=kvantum

    '';

}