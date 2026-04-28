{
  pkgs,
  config,
  lib,
  ...
}: {
  options.myconf.nixos.xdg.enable = lib.mkEnableOption "XDG portals and MIME";

  config = lib.mkIf config.myconf.nixos.xdg.enable {
    # XDG portal
    xdg = {
      portal = {
        enable = true;
        extraPortals = with pkgs; [kdePackages.xdg-desktop-portal-kde];
        xdgOpenUsePortal = true;
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
