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

  # ── Catppuccin palette (all 4 flavors × 26 colors, from catppuccin.com/palette) ──────────
  catppuccinPalettes = {
    latte = {
      rosewater = "dc8a78";
      flamingo = "dd7878";
      pink = "ea76cb";
      mauve = "8839ef";
      red = "d20f39";
      maroon = "e64553";
      peach = "fe640b";
      yellow = "df8e1d";
      green = "40a02b";
      teal = "179299";
      sky = "04a5e5";
      sapphire = "209fb5";
      blue = "1e66f5";
      lavender = "7287fd";
      text = "4c4f69";
      subtext1 = "5c5f77";
      subtext0 = "6c6f85";
      overlay2 = "7c7f93";
      overlay1 = "8c8fa1";
      overlay0 = "9ca0b0";
      surface2 = "acb0be";
      surface1 = "bcc0cc";
      surface0 = "ccd0da";
      base = "eff1f5";
      mantle = "e6e9ef";
      crust = "dce0e8";
    };
    frappe = {
      rosewater = "f2d5cf";
      flamingo = "eebebe";
      pink = "f4b8e4";
      mauve = "ca9ee6";
      red = "e78284";
      maroon = "ea999c";
      peach = "ef9f76";
      yellow = "e5c890";
      green = "a6d189";
      teal = "81c8be";
      sky = "99d1db";
      sapphire = "85c1dc";
      blue = "8caaee";
      lavender = "babbf1";
      text = "c6d0f5";
      subtext1 = "b5bfe2";
      subtext0 = "a5adce";
      overlay2 = "949cbb";
      overlay1 = "838ba7";
      overlay0 = "737994";
      surface2 = "626880";
      surface1 = "51576d";
      surface0 = "414559";
      base = "303446";
      mantle = "292c3c";
      crust = "232634";
    };
    macchiato = {
      rosewater = "f4dbd6";
      flamingo = "f0c6c6";
      pink = "f5bde6";
      mauve = "c6a0f6";
      red = "ed8796";
      maroon = "ee99a0";
      peach = "f5a97f";
      yellow = "eed49f";
      green = "a6da95";
      teal = "8bd5ca";
      sky = "91d7e3";
      sapphire = "7dc4e4";
      blue = "8aadf4";
      lavender = "b7bdf8";
      text = "cad3f5";
      subtext1 = "b8c0e0";
      subtext0 = "a5adcb";
      overlay2 = "939ab7";
      overlay1 = "8087a2";
      overlay0 = "6e738d";
      surface2 = "5b6078";
      surface1 = "494d64";
      surface0 = "363a4f";
      base = "24273a";
      mantle = "1e2030";
      crust = "181926";
    };
    mocha = {
      rosewater = "f5e0dc";
      flamingo = "f2cdcd";
      pink = "f5c2e7";
      mauve = "cba6f7";
      red = "f38ba8";
      maroon = "eba0ac";
      peach = "fab387";
      yellow = "f9e2af";
      green = "a6e3a1";
      teal = "94e2d5";
      sky = "89dceb";
      sapphire = "74c7ec";
      blue = "89b4fa";
      lavender = "b4befe";
      text = "cdd6f4";
      subtext1 = "bac2de";
      subtext0 = "a6adc8";
      overlay2 = "9399b2";
      overlay1 = "7f849c";
      overlay0 = "6c7086";
      surface2 = "585b70";
      surface1 = "45475a";
      surface0 = "313244";
      base = "1e1e2e";
      mantle = "181825";
      crust = "11111b";
    };
  };
  catppuccinFlavor = config.catppuccin.flavor;
  catppuccinAccent = config.catppuccin.accent;
  catppuccinP = catppuccinPalettes.${catppuccinFlavor};
  catppuccinAccentHex = catppuccinP.${catppuccinAccent};
  mkCatppuccinRgb = hex: "rgb(${hex})";
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
        nixPath = ./../../users/mykolas/config/hyprland/lua;
        runtimePath = "${hyprSrcPath}/lua";
        targetPath = "~/.config/hypr/lua";
        filter = name: lib.hasSuffix ".lua" name;
      }).home.activation

      {
        linkHyprlandExtra = lib.hm.dag.entryAfter ["writeBoundary"] ''
          mkdir -p ${hyprTargetPath}

          # Symlink Lua entry point
          rm -f ${hyprTargetPath}/hyprland-dynamic.lua
          ln -s ${hyprSrcPath}/lua/hyprland-dynamic.lua ${hyprTargetPath}/hyprland-dynamic.lua

          # Ensure icon_theme is set in hyprtoolkit.conf (managed by noctalia, which only writes colors)
          # if [ -f ${hyprTargetPath}/hyprtoolkit.conf ] && ! grep -q "icon_theme" ${hyprTargetPath}/hyprtoolkit.conf; then
          #   echo "icon_theme = Papirus-Light" >> ${hyprTargetPath}/hyprtoolkit.conf
          # fi
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
        # Nix-generated Catppuccin palette for Hyprland Lua config.
        # Rebuild home-manager to update when flavor/accent changes.
        "./.config/hypr/lua/catppuccin-palette.lua".text = ''
          -- Nix-generated: do not edit manually.
          -- Controlled by catppuccin.flavor = "${catppuccinFlavor}", catppuccin.accent = "${catppuccinAccent}".
          return {
            rosewater = "${mkCatppuccinRgb catppuccinP.rosewater}",
            flamingo  = "${mkCatppuccinRgb catppuccinP.flamingo}",
            pink      = "${mkCatppuccinRgb catppuccinP.pink}",
            mauve     = "${mkCatppuccinRgb catppuccinP.mauve}",
            red       = "${mkCatppuccinRgb catppuccinP.red}",
            maroon    = "${mkCatppuccinRgb catppuccinP.maroon}",
            peach     = "${mkCatppuccinRgb catppuccinP.peach}",
            yellow    = "${mkCatppuccinRgb catppuccinP.yellow}",
            green     = "${mkCatppuccinRgb catppuccinP.green}",
            teal      = "${mkCatppuccinRgb catppuccinP.teal}",
            sky       = "${mkCatppuccinRgb catppuccinP.sky}",
            sapphire  = "${mkCatppuccinRgb catppuccinP.sapphire}",
            blue      = "${mkCatppuccinRgb catppuccinP.blue}",
            lavender  = "${mkCatppuccinRgb catppuccinP.lavender}",
            text      = "${mkCatppuccinRgb catppuccinP.text}",
            subtext1  = "${mkCatppuccinRgb catppuccinP.subtext1}",
            subtext0  = "${mkCatppuccinRgb catppuccinP.subtext0}",
            overlay2  = "${mkCatppuccinRgb catppuccinP.overlay2}",
            overlay1  = "${mkCatppuccinRgb catppuccinP.overlay1}",
            overlay0  = "${mkCatppuccinRgb catppuccinP.overlay0}",
            surface2  = "${mkCatppuccinRgb catppuccinP.surface2}",
            surface1  = "${mkCatppuccinRgb catppuccinP.surface1}",
            surface0  = "${mkCatppuccinRgb catppuccinP.surface0}",
            base      = "${mkCatppuccinRgb catppuccinP.base}",
            mantle    = "${mkCatppuccinRgb catppuccinP.mantle}",
            crust     = "${mkCatppuccinRgb catppuccinP.crust}",
            -- resolved accent (catppuccin.accent = "${catppuccinAccent}")
            accent    = "${mkCatppuccinRgb catppuccinAccentHex}",
            primary   = "${mkCatppuccinRgb catppuccinAccentHex}",
          }
        '';
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
        "./.config/pypr/config.toml".text = ''
          [pyprland]
          plugins = [
            "scratchpads",
            "wallpapers",
            "expose",
            "shortcuts_menu",
            "toggle_special"
          ]

          [expose]
          include_special = true

          [wallpapers]
          path = "~/.config/wallpapers/catppuccin/${catppuccinFlavor}"
          extentions = ["png", "jpg", "jpeg", "webp"]
          unique = true
          interval = 15
          command = 'awww img --transition-type any "[file]"'
          clear_command = "awww clear"

          [scratchpads.term]
          animation = "fromTop"
          command = "kitty --class kitty-dropterm"
          class = "kitty-dropterm"
          size = "85% 75%"
          max_size = "2400px 100%"
          margin = 50
          allow_special_workspaces = true
          multi = false

          [scratchpads.volume]
          animation = "fromTop"
          command = "pwvucontrol"
          class = "com.saivert.pwvucontrol"
          size = "33% 50%"
          unfocus = "hide"
          lazy = true
          allow_special_workspaces = true

          [shortcuts_menu.entries.Screenshots]
          "Area to clipboard" = "grimblast -t png copysave area"
          "Full screen" = "grimblast -t png copysave screen"
          "Active window" = "grimblast -t png copysave active"
          "Area (3s delay)" = "grimblast -w 3 -t png copysave area"
          "Edit area" = "grimblast -t png edit area"

          [shortcuts_menu.entries.Session]
          "Lock screen" = "session_lock"
          "Logout" = "uwsm stop"

          [shortcuts_menu.entries.Utilities]
          "Clipboard history" = "kitty --class clipse -e clipse"
          "Volume control" = "pypr toggle volume"
          "File manager" = "uwsm app -- kitty -e yazi"
          "Wallpaper cycle" = "pypr wall next"
        '';
        "./.config/xdg-desktop-portal/hyprland-portals.conf".source =
          ./../../users/mykolas/config/hyprland-portals/hyprland-portals.conf;

        # Deploy wallpapers directory (catppuccin/<flavor>/, lockscreen/) into ~/.config/wallpapers
        "./.config/wallpapers" = {
          source = ./../../users/mykolas/config/wallpapers;
          recursive = true;
        };
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      # set the Hyprland and XDPH packages to null to use the ones from the NixOS module package = null;
      portalPackage = null;
      systemd.enable = false;
      configType = "lua";

      plugins = [
        # hypr_plugins_pkgs.hyprexpo
        # pkgs.hyprlandPlugins.hyprexpo
        # hy3_pkgs.hy3
      ];

      xwayland.enable = true;

      extraConfig =
        #lua
        ''
          require("hyprland-dynamic")
          -- require("lua/settings")
          -- require("lua/monitors")
          -- require("lua/workspaces")
          -- require("lua/gestures")
          -- require("lua/startup")
          -- require("lua/binds")
          -- require("lua/window-rules")

        '';
    };

    systemd.user = {
      enable = true;
      tmpfiles.rules = [
        # ensure noctalia directory exists in hyprland config dir
        "d %h/.config/hypr/noctalia 0755 - - -"
      ];
      services = lib.mkMerge [
        (lib.mkIf (!config.myconf.dms.enable) {
          swaync = {
            Unit = {
              Description = "Sway Notification Center";
              ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
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
        })
        {
          hypridle = {
            Unit = {
              Description = "Hyprland Idle Daemon";
              # This keeps it strictly gated to your Hyprland session!
              ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";

              # UWSM activates graphical-session.target once the environment is ready
              BindsTo = ["graphical-session.target"];
              After = ["graphical-session.target"];
            };
            Service = {
              ExecStart = "${pkgs.hypridle}/bin/hypridle";
              Restart = "on-failure";
            };
            Install = {
              WantedBy = ["graphical-session.target"];
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
              ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
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

          # Build the KDE service cache (ksycoca6) at session start so that
          # KDE apps (Dolphin, Gwenview, Okular) can discover app associations via KService.
          # Without this, the cache is never populated in a non-Plasma session.
          kbuildsycoca6 = {
            Unit = {
              Description = "Rebuild KDE service cache for KDE apps (Dolphin, Gwenview, Okular)";
              ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
              After = ["wayland-session@hyprland.desktop.target"];
              PartOf = ["wayland-session@hyprland.desktop.target"];
            };
            Service = {
              Type = "oneshot";
              ExecStart = "${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental";
              RemainAfterExit = true;
            };
            Install = {
              WantedBy = ["wayland-session@hyprland.desktop.target"];
            };
          };

          # Wallpaper daemon — started before pyprland so awww-daemon socket exists
          # when pypr issues the first `awww img` command.
          awww = {
            Unit = {
              Description = "Animated Wayland Wallpaper Daemon";
              ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
              BindsTo = ["wayland-session@hyprland.desktop.target"];
              After = ["wayland-session@hyprland.desktop.target"];
            };
            Service = {
              ExecStart = "${pkgs.awww}/bin/awww-daemon";
              Restart = "on-failure";
            };
            Install = {
              WantedBy = ["wayland-session@hyprland.desktop.target"];
            };
          };
        }
        (lib.mkIf config.hyprconf.noctalia.enable {
          noctalia = let
            noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
          in {
            Unit = {
              Description = "Noctalia shell";
              ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
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
        })
      ];
    };
  };
}
