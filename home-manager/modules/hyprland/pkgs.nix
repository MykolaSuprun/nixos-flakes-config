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
  # Session lock launcher shared by hypridle, keybinds and menus.
  # The noctalia branch launches swaylock instead of "noctalia msg session
  # lock": noctalia v5's native lock screen crashes on resume from suspend
  # ("your lockscreen app died"; upstream EGL context-recovery bugs
  # noctalia#2892/#3916/#1493). pidof guard: only one client can hold the
  # ext-session-lock, so skip if a lock is already active. Wallpaper is the
  # first image dropped in ~/.config/wallpapers/lockscreen/ — passed as a
  # flag only when present, so a missing wallpaper never blocks locking.
  session_lock = pkgs.writeShellScriptBin "session_lock" (
    if (config.myconf.dms.enable or false)
    then ''dms ipc lock lock''
    else if config.hyprconf.noctalia.enable
    then ''
      pidof swaylock >/dev/null && exit 0
      img=$(find "$HOME/.config/wallpapers/lockscreen" -maxdepth 1 -xtype f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | sort | head -n 1)
      if [ -n "$img" ]; then
        exec swaylock --image "$img"
      else
        exec swaylock
      fi
    ''
    else ''hyprlock''
  );
  # fix-lock — restore a broken Hyprland session lock (swaylock).
  #   fix-lock          MANUAL emergency: kill the current lock client and
  #                     start a fresh one. Only run this when the lock is
  #                     actually misbehaving (dead keyboard etc).
  #   fix-lock --auto   PASSIVE safety net (hypridle after_sleep_cmd): acts
  #                     ONLY when logind says the session is locked AND no
  #                     swaylock process exists (lock client died overnight).
  #                     A living swaylock is never touched — the normal
  #                     wake → type password → unlock flow is untouched.
  fix_lock = pkgs.writeShellScriptBin "fix-lock" ''
    launch() {
      img=$(find "$HOME/.config/wallpapers/lockscreen" -maxdepth 1 -xtype f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | sort | head -n 1)
      if [ -n "$img" ]; then
        setsid swaylock --image "$img" </dev/null >/dev/null 2>&1 &
      else
        setsid swaylock </dev/null >/dev/null 2>&1 &
      fi
    }

    if [ "''${1:-}" = "--auto" ]; then
      # Only meaningful inside a running Hyprland session.
      [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || exit 0
      sess="''${XDG_SESSION_ID:-}"
      if [ -z "$sess" ]; then
        sess=$(loginctl list-sessions --no-legend 2>/dev/null \
          | awk -v u="''${USER:-$(id -un)}" '$3 == u { print $1; exit }')
      fi
      [ -n "$sess" ] || exit 0
      # Session not locked → nothing to protect.
      loginctl show-session "$sess" -p LockedHint 2>/dev/null | grep -q '=yes' || exit 0
      # Lock client alive → NORMAL case. Hands off, always.
      pidof swaylock >/dev/null 2>&1 && exit 0
      # Locked but clientless: the lock died while asleep → restore it.
      launch
      exit 0
    fi

    # Manual force-restart: kill whatever is there, start clean.
    pidof swaylock >/dev/null 2>&1 && pkill -x swaylock
    sleep 0.2
    launch
  '';
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

  # ── GPU Runner (per-app AMD PRIME offloading) ─────────────────────────────
  # hypr-gpu-run: rofi menu to launch apps on the dGPU (DRI_PRIME=1) or iGPU (default).
  # The compositor always renders on the iGPU (primary in AQ_DRM_DEVICES); this
  # tool selects WHICH APP uses the dGPU.
  gpu_runner_script = pkgs.writeShellScriptBin "hypr-gpu-run" ''
    CHOICE=$(printf '%s\n' \
      "Run on dGPU (7900 XTX)" \
      "Run on iGPU (Raphael)" \
      "GPU status" \
      "Check render GPU" | rofi -dmenu -i -p "GPU Runner")

    case "$CHOICE" in
      "Run on dGPU (7900 XTX)")
        APP=$(rofi -dmenu -i -p "dGPU:")
        [ -n "$APP" ] && DRI_PRIME=1 eval "$APP" &
        ;;
      "Run on iGPU (Raphael)")
        APP=$(rofi -dmenu -i -p "iGPU:")
        [ -n "$APP" ] && eval "$APP" &
        ;;
      "GPU status")
        STATUS="GPU Devices:
      $(ls -la /dev/dri/igpu /dev/dri/dgpu 2>/dev/null || echo '  no udev symlinks')

      AQ_DRM_DEVICES: ''${AQ_DRM_DEVICES:-unset}

      amdgpu cards:
      $(for c in /dev/dri/card? /dev/dri/card??; do
        [ -e "$c" ] || continue
        echo "  $c"
        udevadm info -q property "$c" 2>/dev/null | grep -E 'ID_PATH=|DRIVER=' | tr '\n' ' '
        echo
      done)"
        notify-send -a "Hyprland" -i "preferences-system" "GPU Status" "$STATUS" -t 15000
        ;;
      "Check render GPU")
        # Read sysfs directly: the card(s) with connected displays are the
        # ones Hyprland drives. Card numbering varies between boots, so we
        # identify by PCI device ID.
        # Verified on this host:
        #   0x164e (card at 59:00.0) = Raphael iGPU
        #   0x744c (card at 03:00.0) = 7900 XTX dGPU
        LABEL=""
        for card in /sys/class/drm/card[0-9]; do
          [ -e "$card/device/device" ] || continue
          DEVID=$(cat "$card/device/device" 2>/dev/null)
          case "$DEVID" in
            0x164e) NAME="Raphael iGPU" ;;
            0x744c) NAME="7900 XTX dGPU" ;;
            *) NAME="unknown (0x$DEVID)" ;;
          esac

          # Check if this card has any connected display
          for conn in "$card"/card*-*-*; do
            [ -e "$conn/status" ] || continue
            [ "$(cat "$conn/status")" = "connected" ] || continue
            LABEL="''${LABEL:+$LABEL, }$NAME (drives display)"
            break
          done
        done

        [ -z "$LABEL" ] && LABEL="no active GPU found"
        notify-send -a "Hyprland" -i "video-card" "Render GPU" "$LABEL" -t 10000
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
    gpu_runner_script
    fix_lock
    hyprlock_script
    hyprlock_script_alt
    hyprlang
    hyprlock
    hyprlauncher
    hyprpwcenter
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
