{...}: {
  programs.waybar = {
    enable = true;
    # systemd.enable = true;
    # systemd.target = "hyprland-session.target";
    style = ''
      * {
          border: none;
          border-radius: 0;
          font-family: JetBrainsMono NF, Roboto, Helvetica, Arial, sans-serif;
          font-size: 13px;
          min-height: 0;
      }

      window#waybar {
          background: alpha(@surface0, 0.9);
          color: @text;

          margin: 5px 10px; /* Adds 5px margin top/bottom,
                            10px left/right. Adjust values as needed. */
          border-radius: 10px; /* Rounds all corners with a 10px radius.
                                Adjust value as needed. */
          /* Optional: Add a subtle shadow for more depth */
          box-shadow: 0 5px 10px rgba(0, 0, 0, 0.3); /* Example shadow */
      }
      #clock {
          background: @base;
          color: @text;
          padding: 0 0.5em;
          margin: 0.25em;
          border-radius: 5px;
      }
      #wireplumber {
          background: @base;
          color: @text;
          padding: 0 0.5em;
          margin: 0.25em;
          border-radius: 5px;
      }
      #bluetooth {
          background: @base;
          color: @text;
          padding: 0 0.5em;
          margin: 0.25em;
          border-radius: 5px;
      }
      #workspaces {
          background: @base;
          color: @text;
          padding: 0 0.5em;
          margin: 0.25em;
          border-radius: 5px;
      }
      #workspaces button {
          padding: 0 0.5em;
          color: @text;
      }
      #workspaces button.active {
          color: @blue;
      }
      #mpris {
          background: @base;
          color: @text;
          padding: 0 0.5em;
          margin: 0.25em;
          border-radius: 5px;
      }
    '';
    settings = {
      mainBar = {
        # output = ["DP-2"];
        layer = "top";
        position = "top";
        height = 40;
        margin-top = 3;
        margin-bottom = 3;
        margin-left = 8;
        margin-right = 8;
        modules-left = ["hyprland/workspaces"];
        modules-center = ["clock"];
        modules-right = ["wireplumber" "mpris" "bluetooth"];
        "hyprland/workspaces" = {
          format = "<span font='16' weight='bold'>{icon}</span>";
          # active-only = true;
          show-special = false;
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "󰭹";
            "7" = "";
            "12" = "";
          };
        };
        "hyprland/language" = {
          format = "Lang: {}";
          # "format-en" = "AMERICA, HELL YEAH!";
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
          tooltip-format-enumerate-connected = "{device_alias}	{device_address}";
          on-click = "hyprctl dispatch exec [floating] overskride";
        };
        wireplumber = {
          format = " {icon} {volume}% ";
          format-muted = "";
          on-click = "hyprctl dispatch exec pypr toggle volume";
          max-volume = 100;
          scroll-step = 10;
          format-icons = ["" "" ""];
        };
        mpris = {
          format = "DEFAULT: {player_icon} {dynamic}";
          format-paused = "DEFAULT: {status_icon} <i>{dynamic}</i>";
          player-icons = {
            default = "▶";
            mpv = "🎵";
          };
          status-icons = {
            paused = "⏸";
          };
        };
      };
    };
  };
}
