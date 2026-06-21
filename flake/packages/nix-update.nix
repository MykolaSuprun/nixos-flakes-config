{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    # 1. Changed from 'nix-update' to camelCase because hyphens are illegal in let-bindings
    nixUpdate = pkgs.writeShellApplication {
      name = "nix-update";

      runtimeInputs = with pkgs; [
        nix
        git
        jq
        fzf
      ];

      text = ''
        # ── Helpers ───────────────────────────────────────────────────────────────────
        log() { printf '\e[1;34m[flake-update]\e[0m %s\n' "$*"; }
        warn() { printf '\e[1;33m[flake-update]\e[0m %s\n' "$*"; }
        err() {
          printf '\e[1;31m[flake-update]\e[0m %s\n' "$*" >&2
          exit 1
        }

        # ── Preflight ─────────────────────────────────────────────────────────────────
        if [[ -z "''${NIXOS_CONF_DIR:-}" ]]; then
          read -erp "NIXOS_CONF_DIR is unset. Enter path to NixOS config: " NIXOS_CONF_DIR
        fi

        [[ -d "$NIXOS_CONF_DIR" ]] || err "Not a valid directory: $NIXOS_CONF_DIR"

        INITIAL_DIR="$PWD"
        cd "$NIXOS_CONF_DIR"

        # ── Input selection ───────────────────────────────────────────────────────────
        ALL_INPUTS=$(nix flake metadata --json | jq -r '.locks.nodes.root.inputs | keys[]')

        if [[ $# -gt 0 ]]; then
          # Explicit inputs passed as CLI arguments
          SELECTED_INPUTS=("$@")
          log "Updating specified inputs: ''${SELECTED_INPUTS[*]}"
        else
          # Interactive multi-select via fzf (guaranteed available)
          # fzf exits 130 on ESC — treat as "all"
          if ! SELECTED_RAW=$(echo "$ALL_INPUTS" | fzf \
            --multi \
            --prompt="flake inputs > " \
            --header="TAB: select  |  CTRL-A: all  |  ESC: update all" \
            --bind="ctrl-a:select-all" \
            --layout=reverse); then
            SELECTED_RAW=""
          fi

          if [[ -z "$SELECTED_RAW" ]]; then
            log "No selection — updating all inputs."
            SELECTED_INPUTS=()
          else
            mapfile -t SELECTED_INPUTS <<<"$SELECTED_RAW"
            log "Updating: ''${SELECTED_INPUTS[*]}"
          fi
        fi

        # ── Update ────────────────────────────────────────────────────────────────────
        if (( ''${#SELECTED_INPUTS[@]} == 0 )); then
          log "Updating all flake inputs..."
          nix flake update --accept-flake-config
        else
          nix flake update --accept-flake-config "''${SELECTED_INPUTS[@]}"
        fi

        # ── Diff ──────────────────────────────────────────────────────────────────────
        if [[ -n "$(git diff flake.lock)" ]]; then
          log "flake.lock diff:"
          git diff flake.lock
        else
          warn "No changes to flake.lock — inputs were already up to date."
        fi

        cd "$INITIAL_DIR"
      ''; # 2. Added the missing closing quotes and semicolon here
    };
  in {
    # 3. Quoted "nix-update" because hyphens are illegal in bare attribute paths
    packages."nix-update" = nixUpdate;
  };
}
