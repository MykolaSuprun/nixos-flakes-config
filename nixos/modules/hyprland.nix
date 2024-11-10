{ inputs, pkgs, ... }: {
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
      # package =
      #   inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      # portalPackage =
      # inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      systemd.setPath.enable = true;
      xwayland.enable = true;
    };
    hyprlock.enable = true;
    uwsm = {
      enable = true;
      waylandCompositors = {
        hyprland = {
          prettyName = "Hyprland";
          comment = "Hyprland compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/Hyprland";
        };
      };
    };
  };
  services.blueman.enable = true;
  services.hypridle.enable = true;
  services.dbus.implementation = "broker";
}
