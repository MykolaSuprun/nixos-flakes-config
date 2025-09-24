{
  config,
  inputs,
  pkgs,
  pkgs-stable,
  ...
}: let
  hyprlock_script = pkgs.writeShellScriptBin "run_hyprlock" ''
    hyprlock
    # swaylock -k -l -i ${config.home.homeDirectory}/.config/hyprlock-background
  '';
  hyprlock_script_alt = pkgs.writeShellScriptBin "run_hyprlock" ''
    hyprlock --config ${config.home.homeDirectory}/.config/hypr/hyprlock.conf.alt
    # swaylock -k -l -i ${config.home.homeDirectory}/.config/hyprlock-background-alt
  '';
  menu_script = pkgs.writeShellScriptBin "run_menu" ''
    # bemenu-run -n -c -B 3 -W 0.3 -l 10 -i -w -H 20 --counter always \ --scrollbar always --binding vim --vim-esc-exits --single-instance \
    #       --fb "#eff1f5" --ff "#4c4f69" --nb "#eff1f5" --nf "#4c4f69" --tb "#eff1f5" \
    #       --hb "#eff1f5" --tf "#d20f39" --hf "#df8e1d" --af "#4c4f69" --ab "#eff1f5" --bdr "#898992"
    rofi -show drun -run-command "uwsm app -- {cmd}"
  '';
  lock_screen = pkgs.writeShellScriptBin "lock_dp1" ''
        state="''${XDG_STATE_HOME}/togglemonitorlock"
        booleanvalue="false"

        if [[ -f ''${state} ]]; then
            booleanvalue=$(cat ''${state})
        fi
    if [[ ''${booleanvalue} == "true" ]]; then
            wlr-randr --output DP-1 --pos 3440,0
            echo "false" > ''${state}
        else
            wlr-randr --output DP-1 --pos 3500,2000
            echo "true" > ''${state}
        fi
  '';
  run_steam = pkgs.writeShellScriptBin "start" ''
    uwsm-app -- ${pkgs.gamescope}/bin/gamescope -f -b -g -e --rt -w 3440 -h 1440 -W 3440 -H 1440 -r 165 \
      --hdr-enabled --force-grab-cursor --immediate-flips \
      --adaptive-sync --backend=wayland --expose-wayland \
      -- ${pkgs.steam}/bin/steam -tenfoot -steamos
  '';
in {
  programs = {};
  home.file = {
    "./.config/uwsm" = {
      source = ./../configurations/mykolas/uwsm;
      recursive = true;
    };
    "./.config/rofi" = {
      source = ./../configurations/mykolas/rofi;
      recursive = true;
    };
    "./.config/hypr/hyprlock-assets" = {
      source = ./../configurations/mykolas/hyprlock/hyprlock-assets;
      recursive = true;
    };
    "./.config/hypr/hyprlock.conf".source =
      ./../configurations/mykolas/hyprlock/hyprlock.conf;
    "./.config/swaync/style.css".source =
      ./../configurations/mykolas/swaync/latte.css;
    "./.config/swaylock/config".source =
      ./../configurations/mykolas/swaylock/latte.conf;
    "./.config/hypr/hyprpaper.conf".source =
      ./../configurations/mykolas/hyprpaper/hyprpaper.conf;
    "./.config/hypr/hyprlock.conf.alt".source =
      ./../configurations/mykolas/hyprlock/hyprlock.conf.alt;
    "./.config/hypr/hypridle.conf".source =
      ./../configurations/mykolas/hypridle/hypridle.conf;
    "./.config/hypr/pyprland.toml".source =
      ./../configurations/mykolas/pyprland/pyprland.toml;
    "./.config/xdg-desktop-portal/hyprland-portals.conf".source =
      ./../configurations/mykolas/hyprland-portals/hyprland-portals.conf;
  };

  # Packages necessary for hyprland
  home.packages = with pkgs; [
    hyprlock
    swaylock
    hyprcursor
    hypridle
    hyprshot
    pyprland
    hyprsysteminfo
    hyprland-qt-support
    hyprutils
    bluejay
    blueberry

    rofi
    rofi-network-manager
    swaynotificationcenter
    # kdePackages.polkit-kde-agent-1
    hyprpolkitagent
    kdePackages.qtwayland
    xorg.xrdb
    dbus-broker
    wlr-randr
    wayland-bongocat
    # hyper
    # terminal
    alacritty-theme
    alacritty
    # pipewire control
    helvum
    # media control
    playerctl
    pwvucontrol # volume control
    # wallpaper engine
    swww
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    # set the Hyprland and XDPH packages to null to use the ones from the NixOS module package = null;
    portalPackage = null;
    systemd.enable = false;
    systemd.variables = ["--all"];

    plugins = with pkgs.hyprlandPlugins; [
      # inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
      # inputs.hyprland-plugins.packages.${pkgs.system}.hyprexpo
      # inputs.hyprland-plugins.packages.${pkgs.system}.hyprtrails
      # inputs.hy3.packages.${pkgs.system}.hy3
      # hy3
      # hyprexpo
    ];

    xwayland.enable = true;

    settings = {
      "$monitor_1" = "desc:ASUSTek COMPUTER INC ASUS VG34V R1LMTF004674";
      "$monitor_2" = "desc:GWD ARZOPA 0x48310206";
      # "$monitor_2" = "DP-2";

      "monitor" = [
        # "$monitor_1,3440x1440@165,0x0,1,bitdepth,10,cm,hdr,sdrbrightness,1.35,sdrsaturation,1.0"
        "$monitor_1,3440x1440@165,0x0,1,bitdepth,10"
        "$monitor_2,2560x1600@60,440x1440,1.6,bitdepth,10,cm,hdr, sdrbrightness,1.4,sdrsaturation,1.0"
        # "DP-1,2560x1440@144,3440x0,1"
      ];

      "$mainMod" = "SUPER";
      "$terminal" = "uwsm app -- ${pkgs.kitty}/bin/kitty";
      "$fileManager" = "uwsm app -- ${pkgs.kitty}/bin/kitty -e lf";
      "$menu" = "${menu_script}/bin/run_menu";

      exec-once = [
        # "${init_script}/bin/pre_init >> /home/mykolas/init_log.txt"
        "systemctl --user enable --now hyprpolkitagent.service"
        "systemctl --user enable --now hypridle.service"
        "[workspace 1 silent] uwsm app -s a zen"
        "[workspace 2 silent] uwsm app -s a kitty"
        "sleep 10 && uwsm app -s a cryptomator &"
        "sleep 11 && uwsm app -s a megasync"
      ];

      general = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more
        "layout" = "hy3";
        "gaps_in" = "3";
        "gaps_out" = "3";
        "border_size" = "3";
        # "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        # "col.inactive_border" = "rgba(595959aa)";
        "no_focus_fallback" = true;
        "resize_on_border" = true;
        # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
        "allow_tearing" = true;
      };

      decoration = {
        "rounding" = 10;
        "inactive_opacity" = 0.98;
      };

      animation = [
        "global, 1, 0.1, default"
      ];

      env = [];

      experimental = {
        "xx_color_management_v4" = true;
      };

      misc = {"vrr" = 1;};

      input = {
        "follow_mouse" = "1";
        "sensitivity" = -0.75;
      };

      cursor = {};

      workspace = [
        "1,monitor:$monitor_1,default:true"
        "2,monitor:$monitor_1,default:false"
        "3,monitor:$monitor_1,default:false"
        "4,monitor:$monitor_1,default:false"
        "4,on-created-empty: pidof Telegram || uwsm app Telegram"
        "7,monitor:$monitor_1,default:false"
        "8,monitor:$monitor_1,default:false"
        "9,monitor:$monitor_1,default:false"
        "10,monitor:$monitor_1,default:false"
        "11,monitor:$monitor_1,default:false"
        "11,on-created-empty: pidof obsidian || uwsm app obsidian"
      ];

      windowrulev2 = [
        "immediate, class:^(gamescope.*)$"
        "fullscreen, class:^(gamescope.*)$"
        "fullscreenstate 3, class:^(gamescope.*)$"
        "immediate, class:^(overwatch.*)$"
        "immediate, class:^(titanfall.*)$"
        # Clair Obscur Uxpedition 33
        "immediate, class:^(steam_app_1903340.*)$"
        "idleinhibit focus, class:^(steam_app_1903340.*)$"
        # Hogwarts Legacy
        "immediate, class:^(steam_app_990080.*)$"
        "immediate, class:^(steam_app_3489700.*)$"
        "immediate, class:^(steam_app_3564860.*)$"
        "idleinhibit focus, class:^(steam_app_3564860.*)$"
        "fullscreen, class:^(titanfall.*)$"
        "immediate, class:^(bioshock.*)$"
        "immediate, class:^(helldivers.*)$"
        "fullscreen, class:^(helldivers.*)$"
        "immediate, class:^(steam_app_2767030.*)$"
        "fullscreen, class:^(steam_app_2767030.*)$"
        "workspace 4 silent, class:^(org.telegram.desktop)$"
        "workspace 12, class:^(steam)$"
        "float,class:^(steam)$"
        "pseudotile,class:^(steam)$"
        "float,class:^(nz.co.mega.)$"
        "workspace special:scratch_hidden silent, class:^(nz.co.mega.)$"
        "float,class:^(xwaylandvideobridge)$"
        "workspace special:scratch_hidden silent, class:^(xwaylandvideobridge)$"
        "float,class:^(org.cryptomator.*)$"
        "workspace special:scratch_hidden silent, class:^(org.cryptomator.*)$"
      ];

      bind =
        [
          "$mainMod, Q, exec, $terminal"
          "$mainMod, C, killactive,"
          "$mainMod CTRL SHIFT, M, exec, uwsm stop "
          # "$mainMod, E, exec, $fileManager"
          "$mainMod, G, togglefloating,"
          "$mainMod SHIFT, Q, exec, ${hyprlock_script}/bin/run_hyprlock"
          "$mainMod CTRL SHIFT, L, exec, ${hyprlock_script_alt}/bin/run_hyprlock"
          "$mainMod SHIFT, Q, exec, "
          "$mainMod CTRL SHIFT, P, exec, hyprshot -m region"
          # "$mainMod, P, pseudo, #"
          "$mainMod, F, fullscreen, 1"
          "$mainMod, R, exec, ${lock_screen}/bin/lock_dp1"
          "$mainMod, N, exec, swaync-client -t"

          "$mainMod SHIFT, F, fullscreen"
          "$mainMod, A,exec, pypr toggle term"
          "$mainMod, S, exec, pypr toggle volume"
          "ALT, SPACE, exec, $menu"

          "$mainMod,I,layoutmsg,addmaster"
          "$mainMod SHIFT,I,layoutmsg,removemaster"
          "$mainMod, H, movefocus, l"
          "$mainMod, L, movefocus, r"
          "$mainMod, K, movefocus, u"
          "$mainMod, J, movefocus, d"
          "$mainMod, mouse_up, focusmonitor,+1"
          "$mainMod, mouse_down, focusmonitor,-1"

          "$mainMod SHIFT, H, movewindow, l"
          "$mainMod SHIFT, L, movewindow, r"
          "$mainMod SHIFT, K, movewindow, u"
          "$mainMod SHIFT, J, movewindow, d"

          "$mainMod SHIFT,O,layoutmsg,orientationcycle left top right bottom center"

          # adjust volume
          ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

          # media buttons
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPrev, exec, playerctl previous"
          ", XF86audiostop, exec, playerctl stop"

          # workspaces
          "$mainMod, =, exec, pypr attach"
          "$mainMod, B, togglespecialworkspace, scratch_hidden"
          "$mainMod SHIFT, B, movetoworkspace, special:scratch_hidden"
          "$mainMod, Y, togglespecialworkspace, scratch_steam"
          "$mainMod SHIFT, Y, movetoworkspace, special:scratch_steam"
          "$mainMod, U, workspace, 1"
          "$mainMod, I, workspace, 2"
          "$mainMod, O, workspace, 3"
          "$mainMod, P, workspace, 4"
          "$mainMod, M, workspace, 11"
          "$mainMod, code:59, workspace, 12"
          "$mainMod, code:60, workspace, 13"
          "$mainMod, code:61, workspace, 14"
          "$mainMod SHIFT, U, movetoworkspace, 1"
          "$mainMod SHIFT, I, movetoworkspace, 2"
          "$mainMod SHIFT, O, movetoworkspace, 3"
          "$mainMod SHIFT, P, movetoworkspace, 4"
          "$mainMod SHIFT, M, movetoworkspace, 11"
          "$mainMod SHIFT, code:59, movetoworkspace, 12"
          "$mainMod SHIFT, code:60, movetoworkspace, 13"
          "$mainMod SHIFT, code:61, movetoworkspace, 14"
        ]
        ++ (
          # workspaces
          # binds $mainMod + [shift +] {1..10} to [move to] workspace {1..10}
          builtins.concatLists (builtins.genList (x: let
              ws = let c = (x + 1) / 10; in builtins.toString (x + 1 - (c * 10));
            in [
              "$mainMod, ${ws}, workspace, ${toString (x + 1)}"
              "$mainMod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
            ])
            10)
        );
      bindm = [
        # Move/resize windows with mainMod + LMB/RMB and dragging
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
    extraConfig = "";
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
}
