{
  config,
  inputs,
  pkgs,
  pkgs-stable,
  lib,
  ...
}: let
  # Use NIXOS_CONF_DIR environment variable defined in geks-nixos.nix
  flakePath = "$NIXOS_CONF_DIR";
  hyprSrcPath = "${flakePath}/home-manager/configurations/mykolas/hyprland/";
  hyprTargetPath = "~/.config/hypr";

  monitorsConf =
    if config.hyprconf.target == "geks-zenbook"
    then "geks-zenbook-monitors.conf"
    else if config.hyprconf.target == "geks-nixos"
    then "geks-nixos-monitors.conf"
    else "monitors-default.conf";

  hyprConfigs = [
    "startup.conf"
    "binds.conf"
    "settings.conf"
    monitorsConf
    "workspaces.conf"
  ];

  filesToLink = srcPath: targetPath: files:
    builtins.map (x: ''
      rm -f ${targetPath}/${x}
      ln -s ${srcPath}/${x} ${targetPath}/${x}
    '')
    files;
in {
  options = {
    hyprconf = {
      target = lib.mkOption {
        type = lib.types.enum ["geks-zenbook" "geks-nixos"];
        description = "Target system determining monitor configuration variant";
        example = "geks-zenbook";
      };
      hyprland = {
        enable = lib.mkEnableOption "enables hyprland config";
      };
    };
  };
  config = lib.mkIf config.hyprconf.hyprland.enable {
    # Create direct symlink to startup.conf in flake repo for live editing
    home.activation.linkHyprlandStartup = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p ${hyprTargetPath}
      mkdir -p ~/.config/wallpapers

      ${lib.strings.concatLines (filesToLink hyprSrcPath hyprTargetPath hyprConfigs)}
    '';

    home.file = {
      "./.config/uwsm" = {
        source = ./../../configurations/mykolas/uwsm;
        recursive = true;
      };
      "./.config/rofi" = {
        source = ./../../configurations/mykolas/rofi;
        recursive = true;
      };
      "./.config/hypr/hyprlock-assets" = {
        source = ./../../configurations/mykolas/hyprlock/hyprlock-assets;
        recursive = true;
      };
      "./.config/hypr/hyprlock.conf".source =
        ./../../configurations/mykolas/hyprlock/hyprlock.conf;
      "./.config/swaync/style.css".source =
        ./../../configurations/mykolas/swaync/latte.css;
      "./.config/swaylock/config".source =
        ./../../configurations/mykolas/swaylock/latte.conf;
      "./.config/hypr/hyprpaper.conf".source =
        ./../../configurations/mykolas/hyprpaper/hyprpaper.conf;
      "./.config/hypr/hyprlock.conf.alt".source =
        ./../../configurations/mykolas/hyprlock/hyprlock.conf.alt;
      "./.config/hypr/hypridle.conf".source =
        ./../../configurations/mykolas/hypridle/hypridle.conf;
      "./.config/hypr/pyprland.toml".source =
        ./../../configurations/mykolas/pyprland/pyprland.toml;
      "./.config/xdg-desktop-portal/hyprland-portals.conf".source =
        ./../../configurations/mykolas/hyprland-portals/hyprland-portals.conf;
    };

    # xdg.configFile = {
    #   "./.config/hypr/hyprlock.conf".source = impurity.link ./../../configurations/mykolas/hyprlock/hyprlock.conf;
    # };

    # xdg.configFile."./config/hypr/hyprlock.conf".source =
    #   impurity.link ./../../configurations/mykolas/hyprlock/hyprlock.conf;

    wayland.windowManager.hyprland = {
      enable = true;
      # set the Hyprland and XDPH packages to null to use the ones from the NixOS module package = null;
      portalPackage = null;
      systemd.enable = false;
      systemd.variables = ["--all"];

      plugins = with pkgs.hyprlandPlugins; [
        hy3
      ];

      xwayland.enable = true;

      extraConfig = ''
        # Source the live-editable startup configuration
        # ${lib.strings.concatLines (builtins.map (x: "source = ${hyprTargetPath}/${x}") hyprConfigs)}
      '';
    };

    systemd.user = {
      enable = true;
      services = {
        # hyprland-hypridle = {
        #   Unit = {
        #     Description = "Idle daemon for hyprland";
        #     After = ["graphical-session.target"];
        #   };
        #   Service = {
        #     Type = "exec";
        #     ExecCondition = ''
        #       ${pkgs.systemd}/lib/systemd/systemd-xdg-autostart-condition "Hyprland" ""'';
        #     ExecStart = "${pkgs.hypridle}/bin/hypridle";
        #     Restart = "on-failure ";
        #     Slice = "background-graphical.slice";
        #   };
        #   Install = {WantedBy = ["hyprland-session.target"];};
        # };
        # hyprland-swaync = {
        #   Unit = {
        #     Description = "Notification daemon for hyprland";
        #     After = [ "graphical-session.target" ];
        #   };
        #   Service = {
        #     Type = "exec";
        #     ExecCondition = ''
        #       ${pkgs.systemd}/lib/systemd/systemd-xdg-autostart-condition "Hyprland" ""'';
        #     ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
        #     Restart = "on-failure ";
        #     Slice = "background-graphical.slice";
        #   };
        #   Install = { WantedBy = [ "hyprland-session.target" ]; };
        # };
      };
    };
  };
}
