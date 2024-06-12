{...}: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
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
        output = ["DP-1"];
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [
          "hyprland/workspaces"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "wireplumber"
        ];
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
            "*" = 5; # 5 workspaces by default on every monitor
          };
        };
        wireplumber = {
          format = " {icon}  {volume}% ";
          format-muted = "";
          on-click = "pwvucontrol";
          max-volume = 100;
          scroll-step = 10;
          format-icons = ["" "" ""];
        };
      };
    };
  };
}
