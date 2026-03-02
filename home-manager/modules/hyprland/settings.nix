{
  config,
  inputs,
  pkgs,
  pkgs-stable,
  lib,
  useHyprlandFlake ? false,
  ...
}: let
  flakePath = config.hyprconf.flakePath;
  hyprSrcPath = "${flakePath}/home-manager/configurations/mykolas/hyprland/";
  hyprTargetPath = "~/.config/hypr";

  hypr_plugins_pkgs =
    if useHyprlandFlake
    then inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}
    else pkgs.hyprlandPlugins;

  hy3_pkgs =
    if useHyprlandFlake
    then inputs.hy3.packages.${pkgs.stdenv.hostPlatform.system}
    else pkgs.hyprlandPlugins;

  monitorsConf =
    if config.hyprconf.target == "geks-zenbook"
    then "geks-zenbook-monitors.conf"
    else if config.hyprconf.target == "geks-nixos"
    then "geks-nixos-monitors.conf"
    else "monitors-default.conf";

  themes = [
    "catppuccin-latte"
    "catppuccin-mocha"
    "catppuccin-frappe"
    "catppuccin-macchiato"
  ];

  accents = [
    "blue"
    "flamingo"
    "green"
    "lavender"
    "maroon"
    "mauve"
    "peach"
    "pink"
    "red"
    "rosewater"
    "sapphire"
    "sky"
    "teal"
    "yellow"
  ];

  hyprConfigs = [
    "settings.conf"
    "startup.conf"
    "binds.conf"
    monitorsConf
    "workspaces.conf"
    "gestures.conf"
  ];

  # Hypr ecosystem configs to symlink but NOT source in hyprland.conf
  hyprEcosystemConfigs = [
    "hyprlauncher.conf"
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
      flakePath = lib.mkOption {
        type = lib.types.str;
        description = "Absolute path to the flake repository for live-edit symlinks";
        example = "/home/mykolas/workspaces/src/nixconf";
      };
      target = lib.mkOption {
        type = lib.types.enum ["geks-zenbook" "geks-nixos"];
        description = "Target system determining hyprland configuration variant";
        example = "geks-zenbook";
      };
      theme = lib.mkOption {
        type = lib.types.enum themes;
        default =
          if config.catppuccin.enable
          then "catppuccin-${config.catppuccin.flavor}"
          else "catppucin-latte";
        description = "Hyprland theme";
        example = "catppucin-latte";
      };
      accent = lib.mkOption {
        type = lib.types.enum accents;
        default =
          if config.catppuccin.enable
          then config.catppuccin.accent
          else "mauve";
        description = "Hyprland theme accent";
        example = "mauve";
      };

      hyprland = {
        enable = lib.mkEnableOption "enables hyprland config";
        flake.enable = lib.mkEnableOption "enables upstream Hyprland flake";
      };
    };
  };
  config = lib.mkIf config.hyprconf.hyprland.enable {
    # Create direct symlink to startup.conf in flake repo for live editing
    home.activation.linkHyprlandStartup = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p ${hyprTargetPath}
      mkdir -p ~/.config/wallpapers

      ${lib.strings.concatLines (filesToLink hyprSrcPath hyprTargetPath hyprConfigs)}
      ${lib.strings.concatLines (filesToLink hyprSrcPath hyprTargetPath hyprEcosystemConfigs)}

      # Ensure icon_theme is set in hyprtoolkit.conf (managed by noctalia, which only writes colors)
      if [ -f ${hyprTargetPath}/hyprtoolkit.conf ] && ! grep -q "icon_theme" ${hyprTargetPath}/hyprtoolkit.conf; then
        echo "icon_theme = Papirus-Light" >> ${hyprTargetPath}/hyprtoolkit.conf
      fi
    '';

    services = {
      # hyprpolkitagent.enable = true;
    };

    programs = {
      hyprshot.enable = true;
    };

    home = {
      pointerCursor.hyprcursor.enable = true;

      file = {
        "./.config/uwsm" = {
          source = ./../../configurations/mykolas/uwsm;
          recursive = true;
        };
        # "./.config/hypr/hyprqt6engine.conf" = {
        #   text = let
        #     themePath = "${config.hyprconf.theme}-${config.hyprconf.accent}";
        #   in
        #     #hyprlang
        #     ''
        #       theme {
        #         color_scheme = ${pkgs.catppuccin-qt5ct}/share/qt6ct/colors/${themePath}
        #         style = "kvantum"
        #       }
        #     '';
        # };
        # disable to manage with noctalia
        # "./.config/hypr/hyprtoolkit.conf" = {
        #   text = let
        #     themePath = "${config.hyprconf.theme}/${config.hyprconf.accent}.conf";
        #     themeFile = ./../../configurations/mykolas/hyprtoolkit/themes + "/${themePath}";
        #     themeConfig = builtins.readFile themeFile;
        #   in ''
        #     ${themeConfig}
        #     # Additional hyprtoolkit configuration
        #     # see https://wiki.hypr.land/Hypr-Ecosystem/hyprtoolkit/ for more details
        #   '';
        # };
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
        "./.config/pypr/config.toml".source =
          ./../../configurations/mykolas/pyprland/pyprland.toml;
        "./.config/xdg-desktop-portal/hyprland-portals.conf".source =
          ./../../configurations/mykolas/hyprland-portals/hyprland-portals.conf;
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      # set the Hyprland and XDPH packages to null to use the ones from the NixOS module package = null;
      portalPackage = null;
      systemd.enable = false;
      systemd.variables = ["--all"];

      plugins = [
        # hypr_plugins_pkgs.hyprexpo
        # pkgs.hyprlandPlugins.hyprexpo
        # hy3_pkgs.hy3
      ];

      xwayland.enable = true;

      extraConfig = ''
        # Source the live-editable startup configuration
        ${lib.strings.concatLines (builtins.map (x: "source = ${hyprTargetPath}/${x}") hyprConfigs)}
      '';
    };

    systemd.user = {
      enable = true;
      tmpfiles.rules = [
        # ensure noctalia directory exists in hyprland config dir
        "d %h/.config/hypr/noctalia 0755 - - -"
      ];
      services = {
        swaync = {
          Unit = {
            Description = "Sway Notification Center";
            BindsTo = ["wayland-session@hyprland.desktop.target"];
            After = ["wayland-session@hyprland.desktop.target"];
          };
          Service = {
            Type = "dbus";
            BusName = "org.freedesktop.Notifications";
            ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
            Restart = "on-failure";
          };
          Install = {
            WantedBy = ["wayland-session@hyprland.desktop.target"];
          };
        };

        hypridle = {
          Unit = {
            Description = "Hyprland Idle Daemon";
            BindsTo = ["wayland-session@hyprland.desktop.target"];
            After = ["wayland-session@hyprland.desktop.target"];
          };
          Service = {
            ExecStart = "${pkgs.hypridle}/bin/hypridle";
            Restart = "on-failure";
          };
          Install = {
            WantedBy = ["wayland-session@hyprland.desktop.target"];
          };
        };

        # clipse = {
        #   Unit = {
        #     Description = "Clipse clipboard manager";
        #     BindsTo = ["wayland-session@hyprland.desktop.target"];
        #     After = ["wayland-session@hyprland.desktop.target"];
        #   };
        #   Service = {
        #     ExecStart = "${pkgs.clipse}/bin/clipse -listen";
        #     Restart = "on-failure";
        #   };
        #   Install = {
        #     WantedBy = ["wayland-session@hyprland.desktop.target"];
        #   };
        # };

        # hyprpaper = {
        #   Unit = {
        #     Description = "Hyprland Wallpaper Daemon";
        #     BindsTo = ["wayland-session@hyprland.desktop.target"];
        #     After = ["wayland-session@hyprland.desktop.target"];
        #   };
        #   Service = {
        #     ExecStart = "${pkgs.hyprpaper}/bin/hyprpaper";
        #     Restart = "on-failure";
        #   };
        #   Install = {
        #     WantedBy = ["wayland-session@hyprland.desktop.target"];
        #   };
        # };

        hyprpolkitagent = {
          Unit = {
            Description = "Hyprland Polkit Authentication Agent";
            BindsTo = ["wayland-session@hyprland.desktop.target"];
            After = ["wayland-session@hyprland.desktop.target"];
          };
          Service = {
            ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
            Restart = "on-failure";
            TimeoutStopSec = "5sec";
            Slice = "session.slice";
          };
          Install = {
            WantedBy = ["wayland-session@hyprland.desktop.target"];
          };
        };

        noctalia = let
          noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
        in {
          Unit = {
            Description = "Noctalia shell";
            BindsTo = ["wayland-session@hyprland.desktop.target"];
            Requisite = ["wayland-session@hyprland.desktop.target"];
            After = ["wayland-session@hyprland.desktop.target"];
          };
          Service = {
            Slice = "app-graphical.slice";
            ExecStart = "${noctaliaPkg}/bin/noctalia-shell --no-duplicate";
            Restart = "on-failure";
            RestartSec = 1;
          };
          Install = {
            WantedBy = ["wayland-session@hyprland.desktop.target"];
          };
        };
        # waybar = {
        #   Unit = {
        #     Description = "Highly customizable Wayland bar";
        #     BindsTo = ["wayland-session@hyprland.desktop.target"];
        #     After = ["wayland-session@hyprland.desktop.target"];
        #   };
        #   Service = {
        #     Slice = "app-graphical.slice";
        #     ExecStart = "${pkgs.waybar}/bin/waybar";
        #     Restart = "on-failure";
        #   };
        #   Install = {
        #     WantedBy = ["wayland-session@hyprland.desktop.target"];
        #   };
        # };
      };
    };
  };
}
