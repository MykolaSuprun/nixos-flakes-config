{
  inputs,
  config,
  pkgs,
  hyprland,
  ...
}: let
  initScript = pkgs.writeShellScriptBin "pre_init" ''
    # launch xdg portal
    sleep 1
    killall -e xdg-desktop-portal-hyprland
    killall -e xdg-desktop-portal-wlr
    killall xdg-desktop-portal
    systemctl start --user xdg-desktop-portal-hyprland &
    sleep 2
    systemctl start --user xdg-desktop-portal &

    systemctl --user import-environment XDG_SESSION_TYPE XDG_CURRENT_DESKTOP &
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
    # fix for xdg-portal
    # exec systemctl --user import-environment PATH && \
    # systemctl --user restart xdg-desktop-portal.service &

    # start polkit agent
    /nix/store/$(ls -la /nix/store | grep polkit-kde-agent | grep '^d' | \
    awk '{print $9}')/libexec/polkit-kde-authentication-agent-1 &

    # a fix for electron apps (run on init to always have it available in cache)
    export LD_LIBRARY_PATH=$(nix build --print-out-paths --no-link nixpkgs#libGL)/lib &

    # Log WLR errors and logs to the hyprland log. Recommended
    export HYPRLAND_LOG_WLR=1

    # set XDG session to wayland & hyprland
    export XDG_SESSION_TYPE="wayland"
    export XDG_SESSION_DESKTOP="Hyprland"
    export XDG_CURRENT_DESKTOP="Hyprland"

    # Set IM to fcitx
    export GTK_IM_MODULE=fcitx
    export QT_IM_MODULE=fcitx
    export XMODIFIERS=@im=fcitx
    export SDL_IM_MODULE=fcitx
    export GLFW_IM_MODULE=fcitx

    # launch fcitx5
    fcitx5 -d --replace &
    fcitx5-remote -r &
    sleep 3 && fcitx5-remote -s keyboard-us &

    # ${pkgs.swww}/bin/swww init &

    # ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator &

    ${pkgs.dunst}/bin/dunst &

    ${pkgs.waybar}/bin/waybar &
  '';
in {
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    xwayland.enable = true;
    systemd.enable = true;
    plugins = [
      # inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
    ];
    settings = {
      exec-once = [
        ''${initScript}/bin/pre_init''
        "[workspace 1 silent] kitty"
        "[workspace 1 silent] firefox"
        "[workspace 2 silent] telegram-desktop"
        "[workspace 2 silent] morgen"
        "[workspace 3 silent] spotify"
      ];
      monitor = [
        "DP-1,3440x1440@165,0x0,1,bitdepth,10"
      ];

      env = [
        "XCURSOR_SIZE,24"
        # XDG
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        # QT
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_QPA_PLATFORM=wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        # "QT_QPA_PLATFORMTHEME,qt5ct" # change to qt6ct if you have that
        "QT_QPA_PLATFORMTHEME,qt6ct"
        # Toolkit
        "SDL_VIDEODRIVER,wayland"
        "_JAVA_AWT_WM_NONEREPARENTING,1"
        "CLUTTER_BACKEND,wayland"
        "GDK_BACKEND,wayland,x11"
      ];

      "$mainMod" = "SUPER";
      "$terminal" = "kitty";
      "$fileManager" = "dolphin";
      "$menu" = "rofi -show drun -show-icons";

      input = {
        sensitivity = "-0.55";
        accel_profile = "flat";
        kb_layout = "us,pl";
        kb_options = "caps:swapescape";
      };

      general = {
        gaps_in = 5;
        gaps_out = 20;

        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";

        layout = "master";
      };
      master = {
        orientation = "center";
      };

      decoration = {
        rounding = 10;

        blur = {
          enabled = true;
          size = 3;
          passes = 1;

          vibrancy = 0.1696;
        };

        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";
      };

      animations = {
        enabled = true;

        # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      windowrule = [
        "pseudo,fcitx"
      ];

      bind = [
        # basic keymaps
        "$mainMod, Q, exec, $terminal"
        "$mainMod, C, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, V, togglefloating,"
        "$mainMod, R, exec, $menu"
        "ALT, SPACE, exec, $menu"
        "$mainMod, P, pseudo, #"
        "$mainMod, S, layoutmsg, swapwithmaster master"
        "$mainMod, F, fullscreen, 1"
        "$mainMod SHIFT, F, fullscreen"
        "$mainMod SHIFT,O,layoutmsg,orientationcycle left top right bottom center"
        "$mainMod,I,layoutmsg,addmaster"
        "$mainMod SHIFT,I,layoutmsg,removemaster"
        "$mainMod ALT SHIFT,L, exec, swaylock-fancy"

        # move focus
        "$mainMod, h, movefocus, l"
        "$mainMod, l, movefocus, r"
        "$mainMod, k, movefocus, u"
        "$mainMod, j, movefocus, d"

        # Switch workspaces with mainMod + [0-9]
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Scroll through existing workspaces with mainMod + scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        # adjust volume
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

        # adjust brightness
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", xf86KbdBrightnessUp, exec, brightnessctl -d *::kbd_backlight set +33%"
        ", xf86KbdBrightnessDown, exec, brightnessctl -d *::kbd_backlight set 33%-"

        # media buttons
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86audiostop, exec, playerctl stop"
      ];

      bindr = [
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };

  programs.waybar = {
    enable = true;
    package = pkgs.waybar;
  };

  home = {
    packages = with pkgs; [
      # terminal (use kitty for hyprland as wezterm is bugged atm)
      kitty
      # screen lock
      swaylock-fancy
      # bar
      waybar
      # app launcher
      rofi-wayland
      # notifications
      dunst
      libnotify
      # wallpaper engine
      swww
      # network applet
      networkmanagerapplet
      # authentication agent
      libsForQt5.polkit-kde-agent
      # qt wayland
      qt6.qtwayland
      libsForQt5.qt5.qtwayland
      # pipewire control
      helvum
      # fonts
      font-manager
      # media control
      playerctl
      pwvucontrol # volume control
    ];

    sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      GLFW_IM_MODULE = "fcitx";
      INPUT_METHOD = "fcitx";
      IMSETTINGS_MODULE = "fcitx";
    };

    pointerCursor = {
      gtk.enable = true;
      # x11.enable = true;
      package = pkgs.catppuccin-cursors.mochaDark;
      name = "Catppuccin-Mocha-Dark-Cursors";
      size = 16;
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Macchiato-Compact-Pink-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = ["pink"];
        size = "compact";
        tweaks = ["rimless" "black"];
        variant = "macchiato";
      };
    };

    iconTheme = {
      package = pkgs.catppuccin-papirus-folders;
      name = "catppuccin-pairus-folders";
    };

    font = {
      name = "Serif";
      size = 10;
    };
  };
}
