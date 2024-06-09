{
  inputs,
  pkgs,
  pkgs-stable,
  # anyrun,
  ...
}: let
  initScript = pkgs.writeShellScriptBin "pre_init" ''
    systemctl --user mask xdg-desktop-portal-wlr
    killall .waybar-wrapped &
    ${pkgs.swaynotificationcenter}/bin/swaync &
    ${pkgs.kdePackages.polkit-kde-agent-1}/pkgs/kde/plasma/polkit-kde-agent-1 &
    ${pkgs.hypridle}/bin/hypridle &
    ${pkgs.swww}/bin/swww-daemon &
    # killall .waybar-wrapped && sleep 4 && waybar &
    sleep 5 && ${pkgs.pyprland}/bin/pypr &
    waybar &
    # swww img ~/.cache/pictures/wallpaper.jpg
    # FILE=~/.config/de_init.sh && test -f $FILE && source $FILE
  '';
  hyprlock_script = pkgs.writeShellScriptBin "run_hyprlock" ''
    #!/usr/bin/env bash
    hyprlock
  '';
in {
  programs = {
    waybar = {
      enable = true;
    };
  };
  # Packages necessary for hyprland
  home.packages = with pkgs; [
    hyprland-protocols
    hyprland-workspaces
    hyprlock
    hyprcursor
    hypridle
    pyprland
    swaynotificationcenter
    kdePackages.polkit-kde-agent-1
    kdePackages.qtwayland
    rofi-wayland
    # hyper
    anyrun
    # terminal
    alacritty-theme
    alacritty
    # pipewire control
    helvum
    # media control
    playerctl
    pkgs-stable.pwvucontrol # volume control
    # wallpaper engine
    swww
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    plugins = [
      # inputs.hy3.packages.x86_64-linux.hy3
      pkgs.hyprlandPlugins.hy3
    ];

    systemd = {
      enable = true;
      enableXdgAutostart = true;
      variables = ["--all"];
    };

    xwayland.enable = true;

    settings = {
      "monitor" = [
        "DP-1,3440x1440@165,0x0,1,bitdepth,10"
        # "DP-2,2560x1440@144,0x0,1"
      ];

      exec-once = [
        "${initScript}/bin/pre_init"
      ];

      "$mainMod" = "SUPER";
      "$fileManager" = "dolphin";
      "$terminal" = "kitty";
      "$menu" = "anyrun";

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
        "allow_tearing" = "true";
      };

      decoration = {
        "rounding" = 10;
        "inactive_opacity" = 0.95;
      };

      env = [
        "WLR_NO_HARDWARE_CURSORS,1"
        "WLR_DRM_eNO_ATOMIC,1"
        "GDK_BACKEND,wayland,x11,*"
        "QT_QPA_PLATFORM,wayland;xcb"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
      ];

      misc = {
        "vrr" = 1;
      };

      input = {
        "follow_mouse" = "1";
        "sensitivity" = -0.6;
      };

      cursor = {
        # "no_warps" = true;
      };

      workspace = [
        "1,monitor:DP-1,default:true,defaultName:default"
        "2,monitor:DP-1,default:false,defaultName:browser"
        "3,monitor:DP-1,default:false,defaultName:code"
        "4,monitor:DP-1,default:false,defaultName:games"
        "7,monitor:DP-2,default:true,defaultName:side_default"
        "8,monitor:DP-2,default:false,defaultName:side_2"
        "9,monitor:DP-2,default:false,defaultName:side_3"
        "0,monitor:DP-2,default:false,defaultName:side_4"
      ];

      windowrulev2 = [
        "immediate, class:^(overwatch.*)$"
        "immediate, class:^(titanfall.*)$"
        "immediate, class:^(bioshock.*)$"
        "immediate, class:^(helldivers.*)$"
        "float,class:(org.telegram.desktop),title:(Media viewer)"
        "float,class:^(org.wezfurlong.wezterm)$"
        "tile,class:^(org.wezfurlong.wezterm)$"
      ];

      bind =
        [
          "$mainMod, Q, exec, $terminal"
          "$mainMod, C, killactive,"
          "$mainMod SHIFT, M, exit"
          "$mainMod, E, exec, $fileManager"
          "$mainMod, V, togglefloating,"
          "$mainMod SHIFT, Q, exec, ${hyprlock_script}/bin/run_hyprlock"
          "$mainMod, P, pseudo, #"
          "$mainMod, F, fullscreen, 1"
          "$mainMod SHIFT, F, fullscreen"
          "$mainMod, A,exec, pypr toggle term"
          "$mainMod SHIFT, V, exec, pypr toggle volume"
          "$mainMod, M, exec, pypr toggle telegram"
          "$mainModu, [, exec, pypr toggle mega"
          "$mainMod, N, exec, pypr toggle obsidian"
          "ALT, SPACE, exec, $menu"

          "$mainMod,I,layoutmsg,addmaster"
          "$mainMod SHIFT,I,layoutmsg,removemaster"
          "$mainMod, H, movefocus, l"
          "$mainMod, L, movefocus, r"
          "$mainMod, K, movefocus, u"
          "$mainMod, J, movefocus, d"

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
        ]
        ++ (
          # workspaces
          # binds $mainMod + [shift +] {1..10} to [move to] workspace {1..10}
          builtins.concatLists (builtins.genList (
              x: let
                ws = let
                  c = (x + 1) / 10;
                in
                  builtins.toString (x + 1 - (c * 10));
              in [
                "$mainMod, ${ws}, workspace, ${toString (x + 1)}"
                "$mainMod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
              ]
            )
            10)
        );
      bindm = [
        # Move/resize windows with mainMod + LMB/RMB and dragging
        "bindm = $mainMod, mouse:272, movewindow"
        "bindm = $mainMod, mouse:273, resizewindow"
      ];
    };
    extraConfig = ''
    '';
  };
}
