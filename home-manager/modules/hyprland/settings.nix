{
  config,
  inputs,
  pkgs,
  pkgs-stable,
  lib,
  useHyprlandFlake ? false,
  ...
}: let
  liveLinks = import ../../../lib/live-links.nix {inherit lib;};

  hyprSrcPath = "${config.home.sessionVariables.NIXOS_CONF_DIR}/home-manager/users/mykolas/config/hyprland";
  hyprTargetPath = "~/.config/hypr";

  hypr_plugins_pkgs =
    if useHyprlandFlake
    then inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}
    else pkgs.hyprlandPlugins;

  hy3_pkgs =
    if useHyprlandFlake
    then inputs.hy3.packages.${pkgs.stdenv.hostPlatform.system}
    else pkgs.hyprlandPlugins;

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
in {
  options = {
    hyprconf = {
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

      noctalia = {
        enable = lib.mkEnableOption "enables noctalia shell service";
      };
    };
  };
  config = lib.mkIf config.hyprconf.hyprland.enable {
    # Symlink Lua config files from flake repo into ~/.config/hypr for live editing.
    home.activation = lib.mkMerge [
      (liveLinks.mkLiveLinks {
        activationName = "linkHyprlandLua";
        nixPath        = ./../../users/mykolas/config/hyprland/lua;
        runtimePath    = "${hyprSrcPath}/lua";
        targetPath     = "~/.config/hypr/lua";
        filter         = name: lib.hasSuffix ".lua" name;
      }).home.activation

      {
        linkHyprlandExtra = lib.hm.dag.entryAfter ["writeBoundary"] ''
          mkdir -p ${hyprTargetPath}
          mkdir -p ~/.config/wallpapers

          # Symlink Lua entry point
          rm -f ${hyprTargetPath}/hyprland.lua
          ln -s ${hyprSrcPath}/lua/hyprland.lua ${hyprTargetPath}/hyprland.lua

          # Ensure icon_theme is set in hyprtoolkit.conf (managed by noctalia, which only writes colors)
          if [ -f ${hyprTargetPath}/hyprtoolkit.conf ] && ! grep -q "icon_theme" ${hyprTargetPath}/hyprtoolkit.conf; then
            echo "icon_theme = Papirus-Light" >> ${hyprTargetPath}/hyprtoolkit.conf
          fi
        '';
      }
    ];

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
          source = ./../../users/mykolas/config/uwsm;
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
        #     themeFile = ./../../users/mykolas/config/hyprtoolkit/themes + "/${themePath}";
        #     themeConfig = builtins.readFile themeFile;
        #   in ''
        #     ${themeConfig}
        #     # Additional hyprtoolkit configuration
        #     # see https://wiki.hypr.land/Hypr-Ecosystem/hyprtoolkit/ for more details
        #   '';
        # };
        "./.config/hypr/hyprlock-assets" = {
          source = ./../../users/mykolas/config/hyprlock/hyprlock-assets;
          recursive = true;
        };
        "./.config/hypr/hyprlock.conf".source =
          ./../../users/mykolas/config/hyprlock/hyprlock.conf;
        "./.config/swaync/style.css".source =
          ./../../users/mykolas/config/swaync/latte.css;
        "./.config/swaylock/config".source =
          ./../../users/mykolas/config/swaylock/latte.conf;
        "./.config/hypr/hyprpaper.conf".source =
          ./../../users/mykolas/config/hyprpaper/hyprpaper.conf;
        "./.config/hypr/hyprlock.conf.alt".source =
          ./../../users/mykolas/config/hyprlock/hyprlock.conf.alt;
        "./.config/hypr/hypridle.conf".source =
          ./../../users/mykolas/config/hypridle/hypridle.conf;
        "./.config/pypr/config.toml".source =
          ./../../users/mykolas/config/pyprland/pyprland.toml;
        "./.config/xdg-desktop-portal/hyprland-portals.conf".source =
          ./../../users/mykolas/config/hyprland-portals/hyprland-portals.conf;
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

      extraConfig = "";
    };

    systemd.user = {
      enable = true;
      tmpfiles.rules = [
        # ensure noctalia directory exists in hyprland config dir
        "d %h/.config/hypr/noctalia 0755 - - -"
      ];
      services =
        {
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
        }
        // lib.optionalAttrs config.hyprconf.noctalia.enable {
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
