{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    nix-update = pkgs.writeShellScriptBin "nix-update" ''
      set -euo pipefail
      FLAKE_DIR="''${NIXOS_CONF_DIR:-$HOME/workspaces/src/nixconf}"
      cd "$FLAKE_DIR"

      # Get all flake input names
      inputs=$(nix flake metadata --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.locks.nodes.root.inputs | keys[]')

      if [ -z "$inputs" ]; then
        echo "No flake inputs found"
        exit 1
      fi

      # Let user select inputs with fzf (multi-select with Tab)
      selected=$(echo "$inputs" | ${pkgs.fzf}/bin/fzf --multi \
        --header="Select inputs to update (Tab to multi-select, Enter to confirm, Ctrl-C for all)" \
        --preview="nix flake metadata --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.locks.nodes[\"{}\"] // empty'" \
        --bind="ctrl-a:select-all" \
        2>/dev/null) || true

      if [ -z "$selected" ]; then
        echo "No selection — updating all inputs..."
        nix flake update --accept-flake-config
      else
        args=""
        for input in $selected; do
          args="$args $input"
        done
        echo "Updating:$args"
        nix flake update $args --accept-flake-config
      fi
    '';
  in {
    packages.nix-update = nix-update;
  };
}
