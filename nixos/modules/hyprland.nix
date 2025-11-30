{
  inputs,
  pkgs,
  config,
  lib,
  useHyprlandFlake ? false,
  ...
}: let
  hypr_pkgs =
    if useHyprlandFlake
    then inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}
    else pkgs;
in {
  options = {
    hyprconf = {
      target = lib.mkOption {
        type = lib.types.enum ["geks-zenbook" "geks-nixos"];
        description = "Target system determining hyprland configuration variant";
        example = "geks-zenbook";
      };
      hyprland = {
        enable = lib.mkEnableOption "enables hyprland config";
        flake.enable = lib.mkEnableOption "enables upstream Hyprland flake";
      };
    };
  };
  config = lib.mkIf config.hyprconf.hyprland.enable {
    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;
        package = hypr_pkgs.hyprland;
        portalPackage = hypr_pkgs.xdg-desktop-portal-hyprland;
        systemd.setPath.enable = true;
        xwayland.enable = true;
      };
      hyprlock = {
        enable = true;
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
      hypridle = {
        enable = true;
        # package = inputs.hypridle.packages.${pkgs.system}.hypridle;
      };
      dbus.implementation = "broker";
    };
  };
}
