{
  config,
  pkgs,
  ...
}: let
  hyprlock_script = pkgs.writeShellScriptBin "run_hyprlock" ''
    hyprlock
    # swaylock -k -l -i ${config.home.homeDirectory}/.config/hyprlock-background
  '';
  hyprlock_script_alt = pkgs.writeShellScriptBin "run_hyprlock_alt" ''
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
in {
  # Packages necessary for hyprland
  home.packages = with pkgs; [
    menu_script
    lock_screen
    hyprlock_script
    hyprlock_script_alt
    hyprlang
    hyprlock
    hyprlauncher
    hyprpwcenter
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
    networkmanagerapplet
    swayosd

    rofi
    rofi-network-manager
    swaynotificationcenter
    libnotify
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
}
