{pkgs, ...}: {
  # XDG portal
  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        kdePackages.xdg-desktop-portal-kde
        # xdg-desktop-portal-hyprland
      ];
      xdgOpenUsePortal = true;
    };
    mime = {
      enable = true;
    };
    menus.enable = true;
    sounds.enable = true;
    icons.enable = true;
    autostart.enable = true;
    terminal-exec.enable = true;
  };
}
