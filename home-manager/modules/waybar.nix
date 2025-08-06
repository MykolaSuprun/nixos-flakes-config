{...}: {
  programs.waybar = {
    enable = true;
    # systemd.enable = true;
    # systemd.target = "hyprland-session.target";
    # window#waybar, tooltip {
    #     background: alpha(@base00, 1.000000);
    # }
    #
    # * {
    #     font-family: "JetBrainsMono Nerd Font";
    #     font-size: 10pt;
    # }
    #
    # @define-color base00 #eff1f5; @define-color base01 #e6e9ef;
    # @define-color base02 #ccd0da; @define-color base03 #bcc0cc;
    # @define-color base04 #acb0be; @define-color base05 #4c4f69;
    # @define-color base06 #dc8a78; @define-color base07 #7287fd;
    #
    # @define-color base08 #d20f39; @define-color base09 #fe640b;
    # @define-color base0A #df8e1d; @define-color base0B #40a02b;
    # @define-color base0C #179299; @define-color base0D #1e66f5;
    # @define-color base0E #8839ef; @define-color base0F #dd7878;
    style = ''
      * {
          border: none;
          border-radius: 0;
          font-family: JetBrainsMono NF, Roboto, Helvetica, Arial, sans-serif;
          font-size: 13px;
          min-height: 0;
      }

      window#waybar {
          background: alpha(@base00, 0.0);

          margin: 5px 10px; /* Adds 5px margin top/bottom,
                            10px left/right. Adjust values as needed. */
          border-radius: 10px; /* Rounds all corners with a 10px radius.
                                Adjust value as needed. */
          /* Optional: Add a subtle shadow for more depth */
          box-shadow: 0 5px 10px rgba(0, 0, 0, 0.3); /* Example shadow */
      }
      #clock {
          padding: 0 0.5em;
          margin: 0.25em;
          border-radius: 5px;
      }
      #wireplumber {
          padding: 0 0.5em;
          margin: 0.25em;
          border-radius: 5px;
      }
      #bluetooth {
          padding: 0 0.5em;
          margin: 0.25em;
          border-radius: 5px;
      }
      #workspaces {
          padding: 0 0.5em;
          margin: 0.25em;
          border-radius: 5px;
      }
      #workspaces button {
          padding: 0 0.5em;
      }
      #workspaces button.active {
      }
      #mpris {
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
          format = "<span font='16' weight='bold'> {icon} </span>";
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
          on-click = "hyprctl dispatch exec [floating] bluejay";
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
