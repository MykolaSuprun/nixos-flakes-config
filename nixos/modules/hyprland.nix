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
        xwayland.enable = true;
      };
      uwsm = {
        enable = true;
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
        enable = false;
        # package = inputs.hypridle.packages.${pkgs.system}.hypridle;
      };
      dbus.implementation = "broker";
    };
  };
}
