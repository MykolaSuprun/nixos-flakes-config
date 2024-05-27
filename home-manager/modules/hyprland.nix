{
  inputs,
  pkgs,
  pkgs-stable,
  hyprland,
  hyprland-plugins,
  hy3,
  anyrun,
  ...
}: let
  initScript = pkgs.writeShellScriptBin "pre_init" ''
    systemctl --user mask xdg-desktop-portal-wlr
    ${pkgs.swaynotificationcenter}/bin/swaync &
    ${pkgs.kdePackages.polkit-kde-agent-1}/pkgs/kde/plasma/polkit-kde-agent-1 &
    ${pkgs.hypridle}/bin/hypridle &
    ${pkgs.swww}/bin/swww-daemon &
    sleep 5 && waybar &
    sleep 5 && ${pkgs.pyprland}/bin/pypr &
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
    anyrun = {
      enable = true;
      config = {
        plugins = [
          # An array of all the plugins you want, which either can be paths to the .so files, or their packages
          inputs.anyrun.packages.${pkgs.system}.applications
          inputs.anyrun.packages.${pkgs.system}.kidex
          inputs.anyrun.packages.${pkgs.system}.websearch
          inputs.anyrun.packages.${pkgs.system}.translate
          # "${inputs.anyrun.packages.${pkgs.system}.anyrun-with-all-plugins}/lib/kidex"
        ];
        x = {fraction = 0.5;};
        y = {fraction = 0.3;};
        width = {fraction = 0.3;};
        hideIcons = false;
        ignoreExclusiveZones = false;
        layer = "overlay";
        hidePluginInfo = false;
        closeOnClick = false;
        showResultsImmediately = false;
        maxEntries = null;
      };
      extraCss = ''
        @define-color bg-col  rgba(30, 30, 46, 0.7);
        @define-color bg-col-light rgba(150, 220, 235, 0.7);
        @define-color border-col rgba(30, 30, 46, 0.7);
        @define-color selected-col rgba(150, 205, 251, 0.7);
        @define-color fg-col #D9E0EE;
        @define-color fg-col2 #F28FAD;

        * {
          transition: 200ms ease;
          font-family: "JetBrainsMono Nerd Font";
          font-size: 1.3rem;
        }

        #window {
          background: transparent;
        }

        #plugin,
        #main {
          border: 3px solid @border-col;
          color: @fg-col;
          background-color: @bg-col;
        }
        /* anyrun's input window - Text */
        #entry {
          color: @fg-col;
          background-color: @bg-col;
        }

        /* anyrun's ouput matches entries - Base */
        #match {
          color: @fg-col;
          background: @bg-col;
        }

        /* anyrun's selected entry - Red */
        #match:selected {
          color: @fg-col2;
          background: @selected-col;
        }

        #match {
          padding: 3px;
          border-radius: 16px;
        }

        #entry, #plugin:hover {
          border-radius: 16px;
        }

        box#main {
          background: rgba(30, 30, 46, 0.7);
          border: 1px solid @border-col;
          border-radius: 15px;
          padding: 5px;
        }
      '';

      extraConfigFiles."some-plugin.ron".text = ''
        Config(
          // for any other plugin
          // this file will be put in ~/.config/anyrun/some-plugin.ron
          // refer to docs of xdg.configFile for available options
        )
      '';
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
    hyper
    anyrun.packages.${system}.anyrun
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
    # package = pkgs-stable.hyprland;

    plugins = [
      # pkgs.hyprlandPlugins.hy3
      hy3.packages.x86_64-linux.hy3
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
        "WLR_DRM_NO_ATOMIC,1"
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

      windowrulev2 = [
        "immediate, class:^(overwatch.*)$"
        "immediate, class:^(titanfall.*)$"
        "immediate, class:^(bioshock.*)$"
        "immediate, class:^(helldivers.*)$"
        "float,class:^(org.wezfurlong.wezterm)$"
        "tile,class:^(org.wezfurlong.wezterm)$"
      ];

      bind =
        [
          "$mainMod, Q, exec, $terminal"
          "$mainMod, C, killactive,"
          "$mainMod, M, exit"
          "$mainMod, E, exec, $fileManager"
          "$mainMod, V, togglefloating,"
          "$mainMod SHIFT, Q, exec, ${hyprlock_script}/bin/run_hyprlock"
          "$mainMod, P, pseudo, #"
          "$mainMod, F, fullscreen, 1"
          "$mainMod SHIFT, F, fullscreen"
          "$mainMod,A,exec,pypr toggle term"
          "ALT, SPACE, exec, $menu"

          "$mainMod,I,layoutmsg,addmaster"
          "$mainMod SHIFT,I,layoutmsg,removemaster"
          "$mainMod, h, movefocus, l"
          "$mainMod, l, movefocus, r"
          "$mainMod, k, movefocus, u"
          "$mainMod, j, movefocus, d"
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
