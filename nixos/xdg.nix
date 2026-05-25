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
        extraPortals = [pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-phosh];
        xdgOpenUsePortal = true;
        config = {
          hyprland = {
            default = ["hyprland" "gtk" "posh"];
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
