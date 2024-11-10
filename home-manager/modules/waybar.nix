{ ... }: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    # systemd.target = "hyprland-session.target";
    style = ''
      * {
        /* reference the color by using @color-name */
        color: @text;
        /* font-family: Serif, Font Awesome, JetBrainsMono Nerd Font; */
        font-family: JetBrainsMono NF
      }

      window#waybar {
        /* you can also GTK3 CSS functions! */
        background-color: shade(@base, 0.9);
        border: 2px solid alpha(@crust, 0.3);
      }
    '';
    settings = {
      mainBar = {
        output = [ "DP-1" ];
        layer = "top";
        position = "top";
        height = 24;
        modules-left = [ "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "bluetooth" "wireplumber" ];
        "hyprland/workspaces" = {
          format = "{icon} ";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
            active = "";
            default = "";
          };
          "persistent-workspaces" = {
            "*" = 8; # 5 workspaces by default on every monitor
          };
        };
        "hyprland/window" = {
          format = " {}";
          rewrite = {
            "(.*) — Mozilla Firefox" = "🌎 $1";
            "(.*) - fish" = "> [$1]";
            "(.*) - tmux" = "> [$1]";
          };
          "separate-outputs" = true;
        };
        bluetooth = {
          format = " {status}";
          format-disabled = "";
          format-connected = " {num_connections} connected";
          tooltip-format = "{controller_alias}	{controller_address}";
          tooltip-format-connected = ''
            {controller_alias}	{controller_address}

            {device_enumerate}'';
          tooltip-format-enumerate-connected =
            "{device_alias}	{device_address}";
          on-click = "hyprctl dispatch exec [floating] blueman-manager";
        };
        wireplumber = {
          format = " {icon} {volume}% ";
          format-muted = "";
          on-click = "hyprctl dispatch exec pypr toggle volume";
          max-volume = 100;
          scroll-step = 10;
          format-icons = [ "" "" "" ];
        };
      };
    };
  };
}
