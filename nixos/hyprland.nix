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
      # Read by the HM hyprland modules (settings.nix) to pick host-specific
      # monitor/GPU values. NOTE: the option is declared separately in the NixOS
      # and HM namespaces — keep both decls in sync.
      target = lib.mkOption {
        type = lib.types.enum ["geks-zenbook" "geks-nixos"];
        default = "geks-nixos";
        description = "Target system determining hyprland configuration variant";
        example = "geks-zenbook";
      };
      hyprland = {
        enable = lib.mkEnableOption "enables hyprland config";
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

    services = {
      dbus.implementation = "broker";
    };
  };
}
