{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    hyprLayoutPicker = pkgs.writeShellApplication {
      name = "hypr-layout-picker";

      # Explicitly declare all dependencies so the script is pure and self-contained
      runtimeInputs = with pkgs; [
        hyprland # provides hyprctl
        jq # JSON parsing

        libnotify # provides notify-send
        coreutils # provides echo, printf, etc.
      ];

      text = ''
        # ── Helpers ───────────────────────────────────────────────────────────────────
        log() { printf '\e[1;34m[hypr-layout-picker]\e[0m %s\n' "$*"; }
        err() {
          printf '\e[1;31m[hypr-layout-picker]\e[0m %s\n' "$*" >&2
          exit 1
        }

        # ── Preflight ─────────────────────────────────────────────────────────────────
        # Ensure the script is actually being run from within a Hyprland session
        if [[ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
          err "HYPRLAND_INSTANCE_SIGNATURE is unset. Are you running Hyprland?"
        fi

        # ── Fetch Workspace ───────────────────────────────────────────────────────────
        WORKSPACE_ID=$(hyprctl activeworkspace -j | jq -r '.id')
        [[ -z "$WORKSPACE_ID" ]] && err "Failed to fetch active workspace ID."

        # ── Prompt User ───────────────────────────────────────────────────────────────
        # Define your available layouts here (lua:tape is the default; the rest
        # are per-workspace fallbacks)
        LAYOUTS="lua:tape\ndwindle\nmaster\nscrolling\nmonocle"

        CHOICE=$(echo -e "$LAYOUTS" | rofi -dmenu -i -p "󰕰 Layout")

        if [[ -z "$CHOICE" ]]; then
            log "No layout selected. Exiting."
            exit 0
        fi

        # ── Apply Layout ──────────────────────────────────────────────────────────────
        log "Switching workspace $WORKSPACE_ID to layout: $CHOICE"

        # We redirect stdout to /dev/null to keep terminal output clean,
        # but hyprctl eval errors will still print to stderr.
        hyprctl eval "hl.workspace_rule({ workspace = \"$WORKSPACE_ID\", layout = \"$CHOICE\" })" >/dev/null

        # ── Notify ────────────────────────────────────────────────────────────────────
        notify-send -a "Hyprland" \
          -i "preferences-desktop-display" \
          "Layout Switched" \
          "Workspace $WORKSPACE_ID is now using $CHOICE"
      '';
    };
  in {
    packages."hypr-layout-picker" = hyprLayoutPicker;
  };
}
