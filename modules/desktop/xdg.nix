_: {
  flake.modules.nixos.xdg = {
    pkgs,
    config,
    lib,
    ...
  }: {
    options.myconf.nixos.xdg.enable = lib.mkEnableOption "XDG portals and MIME";

    config = lib.mkIf config.myconf.nixos.xdg.enable {
      # KService needs a menu that includes applications outside Plasma too.
      environment.systemPackages = [
        (pkgs.writeTextDir "etc/xdg/menus/applications.menu" ''
          <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
            "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
          <Menu>
            <Name>Applications</Name>
            <DefaultAppDirs/>
            <DefaultDirectoryDirs/>
            <DefaultMergeDirs/>
            <Include><All/></Include>
          </Menu>
        '')
      ];

      # Kvantum is a widget style, not a Qt Quick Controls style. Keep the KDE
      # portal's QML dialogs on its own platform theme to prevent chooser crashes.
      systemd.user.services.plasma-xdg-desktop-portal-kde = {
        overrideStrategy = "asDropin";
        environment = {
          QT_QPA_PLATFORMTHEME = "kde";
          QT_QUICK_CONTROLS_STYLE = "org.kde.desktop";
        };
        serviceConfig.UnsetEnvironment = ["QT_STYLE_OVERRIDE"];
      };

      xdg = {
        portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
            pkgs.kdePackages.xdg-desktop-portal-kde
            pkgs.kdePackages.kwallet
          ];
          xdgOpenUsePortal = true;
          config = {
            # XDPH handles compositor interfaces; KDE supplies the Qt/KIO file
            # dialog, GTK the application chooser, and KWallet sandbox secrets.
            hyprland = {
              default = ["hyprland" "gtk"];
              "org.freedesktop.impl.portal.FileChooser" = ["kde"];
              "org.freedesktop.impl.portal.AppChooser" = ["gtk"];
              "org.freedesktop.impl.portal.Secret" = ["kwallet"];
            };
          };
        };
        mime = {enable = true;};
        menus.enable = true;
        sounds.enable = true;
        icons.enable = true;
        autostart.enable = true;
        terminal-exec.enable = true;
      };
    };
  };
}
