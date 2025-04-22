{
  inputs,
  pkgs,
  ...
}: {
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
      package =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      # portalPackage = pkgs.xdg-desktop-portal-hyprland;
      systemd.setPath.enable = true;
      xwayland.enable = true;
    };
    hyprlock = {
      enable = true;
      package = inputs.hyprlock.packages.${pkgs.system}.hyprlock;
    };
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

  # fix for video drivers mismatch causing fps drops when using stable nixos branch
  # hardware.opengl = {
  #   package = pkgs-unstable.mesa.drivers;
  #
  #   # if you also want 32-bit support (e.g for Steam)
  #   driSupport32Bit = true;
  #   package32 = pkgs-unstable.pkgsi686Linux.mesa.drivers;
  # };

  services = {
    blueman.enable = true;
    hypridle = {
      enable = true;
      package = inputs.hypridle.packages.${pkgs.system}.hypridle;
    };
    dbus.implementation = "broker";
  };
}
