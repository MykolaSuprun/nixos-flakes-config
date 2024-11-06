{ inputs, pkgs, pkgs-stable, ... }:
let
  init_script = pkgs.writeShellScriptBin "pre_init" ''
    ${pkgs.swaynotificationcenter}/bin/swaync &
    ${pkgs.kdePackages.polkit-kde-agent-1}/pkgs/kde/plasma/polkit-kde-agent-1 & ${pkgs.hypridle}/bin/hypridle &
    ${pkgs.swww}/bin/swww-daemon &
  '';
  hyprlock_script = pkgs.writeShellScriptBin "run_hyprlock" ''
    hyprlock
  '';
  menu_script = pkgs.writeShellScriptBin "run_menu" ''
    bemenu-run -n -c -B 3 -W 0.3 -l 10 -i -w -H 20 --counter always \
          --scrollbar always --binding vim --vim-esc-exits --single-instance \
          --fb "#eff1f5" --ff "#4c4f69" --nb "#eff1f5" --nf "#4c4f69" --tb "#eff1f5" \
          --hb "#eff1f5" --tf "#d20f39" --hf "#df8e1d" --af "#4c4f69" --ab "#eff1f5" --bdr "#898992"
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
    gamescope -w 3440 -f -g -e -h 1440 -W 3440 -H 1440 -r 165 --hdr-enabled --force-grab-cursor \
      --adaptive-sync --backend wayland --expose-wayland \
      -- steam -tenfoot -steamos -fulldesktopres
  '';
in {
  programs = { };
  home.file = {
    "./.config/hypr/hyprlock.conf".source =
      ./../configurations/mykolas/hyprlock/hyprlock.conf;
    "./.config/hypr/hypridle.conf".source =
      ./../configurations/mykolas/hypridle/hypridle.conf;
    "./.config/hypr/pyprland.toml".source =
      ./../configurations/mykolas/pyprland/pyprland.toml;
    "./.config/xdg-desktop-portal/hyprland-portals.conf".source =
      ./../configurations/mykolas/hyprland-portals/hyprland-portals.conf;
  };

  # Packages necessary for hyprland
  home.packages = with pkgs; [
    hyprland-protocols
    hyprland-workspaces
    hyprland-activewindow
    hyprlock
    hyprcursor
    hypridle
    hyprshot
    pyprland
    blueman
    # swaynotificationcenter
    kdePackages.polkit-kde-agent-1
    kdePackages.qtwayland
    xorg.xrdb
    rofi-wayland
    wlr-randr
    # hyper
    anyrun
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
    package =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

    plugins = with pkgs.hyprlandPlugins; [
      inputs.hy3.packages.${pkgs.system}.hy3
      inputs.hyprland-plugins.packages.${pkgs.system}.hyprexpo
      # hy3
      # hyprexpo
      # hyprspace
      # hyprfocus
    ];

    systemd = {
      enable = true;
      enableXdgAutostart = true;
      variables = [ "--all" ];
    };

    xwayland.enable = true;

    settings = {
      "monitor" = [
        "DP-1,3440x1440@165,0x0,1,bitdepth,10"
        # "DP-1,2560x1440@144,3440x0,1"
      ];

      exec-once = [
        "systemctl --user mask xdg-desktop-portal-wlr"
        "systemctl --user import-environment XDG_SESSION_TYPE XDG_CURRENT_DESKTOP"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "${init_script}/bin/pre_init"
        "pypr --debug /tmp/pypr.log"
        "[workspace 1 silent] firefox"
        "[workspace 2 silent] kitty lf"
        "[workspace 3 silent] kitty"
        "[workspace 4 silent] ${run_steam}/bin/start"
      ];

      "$mainMod" = "SUPER";
      "$fileManager" = "kitty lf";
      "$terminal" = "kitty";
      # "$menu" = "anyrun";
      "$menu" = "${menu_script}/bin/run_menu";
      "$monitor_1" = "DP-1";
      "$monitor_2" = "DP-2";

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

      env = [
        "WLR_NO_HARDWARE_CURSORS,1"
        "WLR_DRM_eNO_ATOMIC,1"
        "GDK_BACKEND,wayland,x11,*"
        # XDG
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        # QT
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        # Toolkit
        "SDL_VIDEODRIVER,wayland"
        "_JAVA_AWT_WM_NONEREPARENTING,1"
        "CLUTTER_BACKEND,wayland"
        "GDK_BACKEND,wayland,x11"
      ];

      misc = { "vrr" = 1; };

      input = {
        "follow_mouse" = "1";
        "sensitivity" = -0.6;
      };

      cursor = { };

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
        "immediate, class:^(overwatch.*)$"
        "immediate, class:^(titanfall.*)$"
        "immediate, class:^(bioshock.*)$"
        "immediate, class:^(helldivers.*)$"
        "float,class:(org.telegram.desktop),title:(Media viewer)"
        "float,class:^(org.wezfurlong.wezterm)$"
        "tile,class:^(org.wezfurlong.wezterm)$"
      ];

      bind = [
        "$mainMod, Q, exec, $terminal"
        "$mainMod, C, killactive,"
        "$mainMod CTRL SHIFT, M, exit"
        # "$mainMod, E, exec, $fileManager"
        "$mainMod, G, togglefloating,"
        "$mainMod SHIFT, Q, exec, ${hyprlock_script}/bin/run_hyprlock"
        "$mainMod CTRL SHIFT, P, exec, hyprshot -m region"
        # "$mainMod, P, pseudo, #"
        "$mainMod, F, fullscreen, 1"
        "$mainMod, R, exec, ${lock_screen}/bin/lock_dp1"

        "$mainMod SHIFT, F, fullscreen"
        "$mainMod, A,exec, pypr toggle term"
        "$mainMod, S, exec, pypr toggle volume"
        "$mainMod, M, exec, pypr toggle telegram"
        "$mainModu, [, exec, pypr toggle mega"
        "$mainMod, N, exec, pypr toggle obsidian"
        "$mainMod SHIFT, S, exec, ${run_steam}/bin/start"
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
        "$mainMod, U, workspace, 1"
        "$mainMod, I, workspace, 2"
        "$mainMod, O, workspace, 3"
        "$mainMod, P, workspace, 4"
        "$mainMod SHIFT, U, movetoworkspace, 1"
        "$mainMod SHIFT, I, movetoworkspace, 2"
        "$mainMod SHIFT, O, movetoworkspace, 3"
        "$mainMod SHIFT, P, movetoworkspace, 4"
      ] ++ (
        # workspaces
        # binds $mainMod + [shift +] {1..10} to [move to] workspace {1..10}
        builtins.concatLists (builtins.genList (x:
          let
            ws = let c = (x + 1) / 10; in builtins.toString (x + 1 - (c * 10));
          in [
            "$mainMod, ${ws}, workspace, ${toString (x + 1)}"
            "$mainMod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
          ]) 10));
      bindm = [
        # Move/resize windows with mainMod + LMB/RMB and dragging
        "bindm = $mainMod, mouse:272, movewindow"
        "bindm = $mainMod, mouse:273, resizewindow"
      ];
    };
    extraConfig = "";
  };
}
