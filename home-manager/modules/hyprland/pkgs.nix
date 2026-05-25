{
  inputs,
  config,
  pkgs,
  system,
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
  hypr_binds_script = pkgs.writeShellScriptBin "hypr-binds-list" ''
    # Rofi script-mode adapter for Hyprland keybind cheat sheet.
    # Called with no arguments: print all described binds, one per line.
    # Called with a selection argument: no-op (cheat sheet is read-only).
    if [ $# -eq 0 ]; then
      hyprctl binds -j | \
        ${pkgs.jq}/bin/jq -r '
          def getbit($p; $n): fmod($n / ($p | exp2) | floor; 2) | fabs;
          .[] | select(.description != "") |
          .a = "" |
          ( if getbit(6; .modmask) == 1 then .a = .a + "SUPER + " end |
            if getbit(0; .modmask) == 1 then .a = .a + "Shift + " end |
            if getbit(2; .modmask) == 1 then .a = .a + "Ctrl + " end |
            if getbit(3; .modmask) == 1 then .a = .a + "Alt + " end ) |
          .description + "|" + .a + .key
        ' | ${pkgs.util-linux}/bin/column -t -s "|"
    fi
  '';
  session_lock = pkgs.writeShellScriptBin "session_lock" (
    if config.myconf.dms.enable
    then ''dms ipc lock lock''
    else if config.myconf.noctalia.enable
    then ''noctalia-shell ipc call lockScreen lock''
    else ''hyprlock''
  );
  notification_toggle = pkgs.writeShellScriptBin "notification-panel-toggle" (
    if config.myconf.dms.enable
    then ''dms ipc notifications toggle''
    else ''swaync-client -t''
  );
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
    # inputs.caelestia-shell.packages.${system}.with-cli
    menu_script
    hypr_binds_script
    session_lock
    notification_toggle
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
    grimblast
    pyprland
    hyprsysteminfo
    hyprland-qt-support
    hyprutils
    bluejay
    networkmanagerapplet
    swayosd
    app2unit

    kdePackages.qt6ct
    rofi-network-manager
    swaynotificationcenter
    libnotify
    # kdePackages.polkit-kde-agent-1
    hyprpolkitagent
    kdePackages.qtwayland
    xrdb
    dbus-broker
    wlr-randr
    wayland-bongocat
    # hyper
    # terminal
    # pipewire control
    # media control
    playerctl
    pwvucontrol # volume control
    # wallpaper engine
    awww
  ];
}
