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
    if (config.myconf.dms.enable or false)
    then ''dms ipc lock lock''
    else if config.myconf.noctalia.enable
    then ''noctalia-shell ipc call lockScreen lock''
    else ''hyprlock''
  );
  notification_toggle = pkgs.writeShellScriptBin "notification-panel-toggle" (
    if (config.myconf.dms.enable or false)
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
  # Toggle Hyprland monitors on/off at runtime without editing the config.
  # Persists the disabled state in $XDG_STATE_HOME/hypr/monitor-state, which the
  # host-specific monitors.lua reads at startup, so toggles survive restarts.
  # Usage:
  #   monitor-toggle            rofi menu (pick which monitor to toggle)
  #   monitor-toggle main       toggle main monitor directly (geks-nixos)
  #   monitor-toggle secondary  toggle secondary monitor directly (geks-nixos)
  monitor_toggle = pkgs.writeShellScriptBin "monitor-toggle" ''
    HOSTNAME=$(cat /etc/hostname 2>/dev/null || echo unknown)

    STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
    STATE_FILE="$STATE_DIR/monitor-state"
    mkdir -p "$STATE_DIR"
    [ -f "$STATE_FILE" ] || : > "$STATE_FILE"

    # geks-nixos dual-monitor setup
    MONITOR_MAIN="desc:ASUSTek COMPUTER INC ASUS VG34V R1LMTF004674"
    MONITOR_SECONDARY="desc:GWD ARZOPA 0x48310206"

    notify() { notify-send -a monitor-toggle "$1" || true; }

    # read_state <key> → "true" (disabled) or "false"
    read_state() {
      local v
      v=$(sed -n "s|^$1=||p" "$STATE_FILE")
      [ "$v" = "true" ] && echo true || echo false
    }

    # set_state <key> <true|false>
    set_state() {
      sed -i "/^$1=/d" "$STATE_FILE"
      printf '%s=%s\n' "$1" "$2" >> "$STATE_FILE"
    }

    # apply <descriptor> <true=enable|false=disable>
    # Lua config: `hyprctl keyword` is legacy-only and returns
    # "keyword can't work with non-legacy parsers. Use eval.", so we toggle
    # via `hyprctl eval`. hl.monitor() merges with the existing rule,
    # preserving mode/position/scale — only the disabled flag is flipped.
    apply() {
      local out
      out=$(hyprctl eval "hl.monitor({ output = \"$1\", disabled = $2 })" 2>&1)
      case "$out" in
        ok) ;;
        *) notify "monitor-toggle: $out" ;;
      esac
    }

    # toggle_monitor <state-key> <descriptor> <label> — flip persisted state, apply live
    toggle_monitor() {
      local key="$1" desc="$2" label="$3" cur new count
      cur=$(read_state "$key")
      if [ "$cur" = "true" ]; then new=false; else new=true; fi

      # Never leave the session without an active monitor.
      if [ "$new" = "true" ]; then
        count=$(${pkgs.jq}/bin/jq length < <(hyprctl monitors -j 2>/dev/null))
        if [ "$count" -le 1 ]; then
          notify "Refusing to disable $label: it is the last active monitor."
          return 1
        fi
      fi

      set_state "$key" "$new"
      apply "$desc" "$new"
      if [ "$new" = "true" ]; then
        notify "$label disabled"
      else
        notify "$label enabled"
      fi
    }

    # geks-nixos: static main/secondary menu with persisted state.
    menu_geks() {
      local ms ss me se choice
      ms=$(read_state main_disabled)
      ss=$(read_state secondary_disabled)
      if [ "$ms" = "true" ]; then me="Main (ASUS VG34V)  [disabled]"; else me="Main (ASUS VG34V)  [enabled]"; fi
      if [ "$ss" = "true" ]; then se="Secondary (ARZOPA)  [disabled]"; else se="Secondary (ARZOPA)  [enabled]"; fi

      choice=$(printf '%s\n%s\n' "$me" "$se" | rofi -dmenu -p "Monitor toggle")
      [ -z "$choice" ] && return 0
      if [ "$choice" = "$me" ]; then
        toggle_monitor main_disabled "$MONITOR_MAIN" "Main monitor"
      elif [ "$choice" = "$se" ]; then
        toggle_monitor secondary_disabled "$MONITOR_SECONDARY" "Secondary monitor"
      fi
    }

    # Other hosts: list connected monitors plus previously disabled ones from
    # the state file (keyed by monitor name).
    menu_generic() {
      local list choice name
      list=$(
        {
          hyprctl monitors -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[].name'
          sed -n 's|^mon_\(.*\)=true$|\1|p' "$STATE_FILE"
        } | sort -u
      )
      [ -z "$list" ] && { notify "No monitors found"; return 0; }

      choice=$(printf '%s\n' "$list" | while read -r name; do
        if [ "$(read_state "mon_$name")" = "true" ]; then
          printf '%s  [disabled]\n' "$name"
        else
          printf '%s  [enabled]\n' "$name"
        fi
      done | rofi -dmenu -p "Monitor toggle")
      [ -z "$choice" ] && return 0

      name=''${choice%  *}
      toggle_monitor "mon_$name" "$name" "$name"
    }

    case "''${1:-}" in
      main) toggle_monitor main_disabled "$MONITOR_MAIN" "Main monitor" ;;
      secondary) toggle_monitor secondary_disabled "$MONITOR_SECONDARY" "Secondary monitor" ;;
      *)
        if [ "$HOSTNAME" = "geks-nixos" ]; then
          menu_geks
        else
          menu_generic
        fi
        ;;
    esac
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
    monitor_toggle
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
