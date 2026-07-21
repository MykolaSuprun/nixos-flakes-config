{
  pkgs,
  config,
  lib,
  ...
}: {
  options.myconf.nixos.xdg.enable = lib.mkEnableOption "XDG portals and MIME";

  config = lib.mkIf config.myconf.nixos.xdg.enable {
    # kbuildsycoca6 requires an applications.menu file in XDG_CONFIG_DIRS to
    # enumerate installed apps. No package provides one outside a Plasma session,
    # so inject a minimal FreeDesktop-compliant one here.
    environment.systemPackages = [
      (pkgs.writeTextDir "etc/xdg/menus/applications.menu" ''
        <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
          "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
        <Menu>
          <Name>Applications</Name>
          <DefaultAppDirs/>
          <DefaultDirectoryDirs/>
          <DefaultMergeDirs/>
        </Menu>
      '')
    ];

    # XDG portal
    xdg = {
      portal = {
        enable = true;
        # xdg-desktop-portal-gtk stays installed as a fallback for interfaces
        # neither XDPH nor KDE implement (Settings/AppChooser for Flatpak apps).
        # It's pulled out of the per-desktop default lists below so it never
        # serves the FileChooser — that's routed to the KDE portal (Dolphin)
        # on Hyprland, and to kde on Plasma.
        # xdg-desktop-portal-phosh was previously listed but never matched
        # (selection files referenced "posh", not "phosh") — pure dead weight.
        extraPortals = [pkgs.xdg-desktop-portal-gtk];
        xdgOpenUsePortal = true;
        config = {
          # Pattern documented on the Hyprland wiki: XDPH owns Hyprland-native
          # interfaces (screenshare, global shortcuts), gtk covers the gaps, and
          # the FileChooser interface is explicitly routed to kde so Dolphin is
          # the picker (Qt), not a GTK dialog.
          hyprland = {
            default = ["hyprland" "gtk"];
            "org.freedesktop.impl.portal.FileChooser" = ["kde"];
          };
          # Pin Plasma's portal explicitly so the plasma6 module's
          # implicit portal deps don't drift if upstream changes defaults.
          kde = {
            default = ["kde"];
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
}
