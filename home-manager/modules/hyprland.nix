{
  config,
  inputs,
  pkgs,
  pkgs-stable,
  ...
}: let
  hyprlock_script = pkgs.writeShellScriptBin "run_hyprlock" ''
    uwsm-app -- hyprlock
  '';
  hyprlock_script_alt = pkgs.writeShellScriptBin "run_hyprlock" ''
    uwsm-app -- hyprlock --config ${config.home.homeDirectory}/.config/hypr/hyprlock.conf.alt
  '';
  menu_script = pkgs.writeShellScriptBin "run_menu" ''
    # bemenu-run -n -c -B 3 -W 0.3 -l 10 -i -w -H 20 --counter always \ --scrollbar always --binding vim --vim-esc-exits --single-instance \
    #       --fb "#eff1f5" --ff "#4c4f69" --nb "#eff1f5" --nf "#4c4f69" --tb "#eff1f5" \
    #       --hb "#eff1f5" --tf "#d20f39" --hf "#df8e1d" --af "#4c4f69" --ab "#eff1f5" --bdr "#898992"
    rofi -show drun -run-command "uwsm-app -- {cmd}"
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
  init_script = pkgs.writeShellScriptBin "pre_init" ''
    # uwsm-app -- ${pkgs.waybar}/bin/waybar
    # uwsm-app -- ${pkgs.hypridle}/bin/hypridle &
    # uwsm-app -- ${pkgs.swaynotificationcenter}/bin/swaync &
    # uwsm-app -- ${pkgs.swww}/bin/swww-daemon &&
    # uwsm-app -- ${pkgs.pyprland}/bin/pypr --debug /tmp/pypr.log

  '';
in {
  wayland.windowManager.hyprland.systemd.enable = false;
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
    hyprcursor
    hypridle
    hyprshot
    pyprland
    blueman
    swaynotificationcenter
    kdePackages.polkit-kde-agent-1
    kdePackages.qtwayland
    xorg.xrdb
    rofi-wayland
    dbus-broker
    wlr-randr
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
    # package =
    #   inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # portalPackage =
    #   inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

    plugins = with pkgs.hyprlandPlugins; [
      # inputs.hy3.packages.${pkgs.system}.hy3
      # inputs.hyprland-plugins.packages.${pkgs.system}.hyprexpo
      # hy3
      # hyprexpo
      # hyprspace
      # hyprfocus
    ];

    xwayland.enable = true;

    settings = {
      "$monitor_1" = "desc:ASUSTek COMPUTER INC ASUS VG34V R1LMTF004674";
      # "$monitor_2" = "DP-2";

      "monitor" = [
        "$monitor_1,3440x1440@165,0x0,1,bitdepth,10,cm,hdr,sdrbrightness,1.35,sdrsaturation,1.0"
        # "DP-1,2560x1440@144,3440x0,1"
      ];

      "$mainMod" = "SUPER";
      "$fileManager" = "uwsm-app -- ${pkgs.wezterm}/bin/wezterm lf";
      "$terminal" = "uwsm-app -- ${pkgs.wezterm}/bin/wezterm";
      "$menu" = "${menu_script}/bin/run_menu";

      exec-once = [
        # "${init_script}/bin/pre_init >> /home/mykolas/init_log.txt"
        "[workspace 1 silent] sleep 1 && uwsm-app zen"
        "[workspace 2 silent] sleep 3 && uwsm-app wezterm"
        "sleep 5 && uwsm-app steam &"
        "sleep 10 && uwsm-app cryptomator &"
        "sleep 11 && uwsm-app megasync"
      ];

      general = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more
        "layout" = "hy3";
        "gaps_in" = "3";
        "gaps_out" = "3";
        "border_size" = "3";
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        "no_focus_fallback" = true;
        "resize_on_border" = true;
        # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
        "allow_tearing" = true;
      };

      decoration = {
        "rounding" = 10;
        "inactive_opacity" = 0.95;
      };

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
        "1,monitor:$monitor_1,default:true,defaultName:default"
        "2,monitor:$monitor_1,default:false,defaultName:code"
        "3,monitor:$monitor_1,default:false,defaultName:filemanager"
        "4,monitor:$monitor_1,default:false,defaultName:other"
        "7,monitor:$monitor_1,default:false,defaultName:side_default"
        "8,monitor:$monitor_1,default:false,defaultName:steam"
        "9,monitor:$monitor_1,default:false,defaultName:side_3"
        "0,monitor:$monitor_1,default:false,defaultName:side_4"
      ];

      windowrulev2 = [
        "immediate, class:^(gamescope.*)$"
        "fullscreen, class:^(gamescope.*)$"
        "fullscreenstate 3, class:^(gamescope.*)$"
        "immediate, class:^(overwatch.*)$"
        "immediate, class:^(titanfall.*)$"
        "fullscreen, class:^(titanfall.*)$"
        "immediate, class:^(bioshock.*)$"
        "immediate, class:^(helldivers.*)$"
        "fullscreen, class:^(helldivers.*)$"
        "immediate, class:^(steam_app_2767030.*)$"
        "fullscreen, class:^(steam_app_2767030.*)$"
        "float,class:^(org.telegram.desktop)$"
        "float,class:^(nz.co.mega.)$"
        "workspace special:scratch_hidden silent, class:^(nz.co.mega.)$"
        "float,class:^(org.cryptomator.*)$"
        "workspace special:scratch_hidden silent, class:^(org.cryptomator.*)$"
        "workspace special:scratch_steam silent, class:^(steam)$"
        "fullscreen, class:^(steam)$"
      ];

      bind =
        [
          "$mainMod, Q, exec, $terminal"
          "$mainMod, C, killactive,"
          "$mainMod CTRL SHIFT, M, exec, uwsm stop"
          # "$mainMod, E, exec, $fileManager"
          "$mainMod, G, togglefloating,"
          "$mainMod SHIFT, Q, exec, ${hyprlock_script}/bin/run_hyprlock"
          "$mainMod CTRL SHIFT, L, exec, ${hyprlock_script_alt}/bin/run_hyprlock"
          "$mainMod SHIFT, Q, exec, "
          "$mainMod CTRL SHIFT, P, exec, hyprshot -m region"
          # "$mainMod, P, pseudo, #"
          "$mainMod, F, fullscreen, 1"
          "$mainMod, R, exec, ${lock_screen}/bin/lock_dp1"

          "$mainMod SHIFT, F, fullscreen"
          "$mainMod, A,exec, pypr toggle term"
          "$mainMod, S, exec, pypr toggle volume"
          "$mainMod, M, exec, pypr toggle telegram"
          "$mainMod, N, exec, pypr toggle obsidian"
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
          "$mainMod SHIFT, U, movetoworkspace, 1"
          "$mainMod SHIFT, I, movetoworkspace, 2"
          "$mainMod SHIFT, O, movetoworkspace, 3"
          "$mainMod SHIFT, P, movetoworkspace, 4"
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
      hyprland-hypridle = {
        Unit = {
          Description = "Idle daemon for hyprland";
          After = ["graphical-session.target"];
        };
        Service = {
          Type = "exec";
          ExecCondition = ''
            ${pkgs.systemd}/lib/systemd/systemd-xdg-autostart-condition "Hyprland" ""'';
          ExecStart = "${pkgs.hypridle}/bin/hypridle";
          Restart = "on-failure ";
          Slice = "background-graphical.slice";
        };
        Install = {WantedBy = ["hyprland-session.target"];};
      };
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
