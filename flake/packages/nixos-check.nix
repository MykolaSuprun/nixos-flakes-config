# Interactive validation script for NixOS configurations.
# Supports dry-run per-host config eval and full `nix flake check`.
# vim-style keybindings: j/k=navigate, g/G=top/bottom, ctrl-d/u=half-page.
{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    nixos-check = pkgs.writeShellApplication {
      name = "nixos-check";
      runtimeInputs = [pkgs.jq pkgs.fzf];
      text = ''
        # Set FLAKE_REF to override the source flake (e.g. FLAKE_REF=. for local).
        FLAKE_REF="''${FLAKE_REF:-github:MykolaSuprun/nixos-flakes-config}"

        # Determinate Nix substituter flags — required on first run / fresh systems
        # to avoid compiling Determinate Nix from source (no-op on v3.6.0+).
        DETERMINATE_OPTS=(
          --accept-flake-config
          --show-trace
          --option extra-substituters https://install.determinate.systems
          --option extra-trusted-public-keys "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
        )

        FZF_BIND=(--bind "j:down,k:up,g:first,G:last,ctrl-d:half-page-down,ctrl-u:half-page-up")

        # --- Host discovery -------------------------------------------------------
        all_hosts=$(nix eval "''${FLAKE_REF}#nixosConfigurations" \
          --apply builtins.attrNames --json \
          --accept-flake-config 2>/dev/null \
          | jq -r '.[]')

        if [ -z "$all_hosts" ]; then
          echo "error: no nixosConfigurations found in flake" >&2
          exit 1
        fi

        # --- Host selection (TAB for multi-select) --------------------------------
        selected=$(echo "$all_hosts" \
          | fzf \
              --multi \
              --header "Select hosts to validate (TAB=multi-select, ENTER=confirm):" \
              --prompt "host> " \
              "''${FZF_BIND[@]}") || { echo "Aborted." >&2; exit 1; }

        # --- Check mode selection -------------------------------------------------
        mode=$(printf "eval\nflake-check\nboth" \
          | fzf \
              --header "Select check mode:  eval=dry-run per host | flake-check=all outputs | both" \
              --prompt "mode> " \
              "''${FZF_BIND[@]}") || { echo "Aborted." >&2; exit 1; }

        passed=()
        failed=()

        # Dry-run evaluation of a single host's system toplevel.
        do_eval() {
          local host="$1"
          echo ""
          echo ">>> Evaluating: $host"
          if nix build "''${FLAKE_REF}#nixosConfigurations.''${host}.config.system.build.toplevel" \
              --dry-run "''${DETERMINATE_OPTS[@]}"; then
            passed+=("$host")
            echo "    PASS: $host"
          else
            failed+=("$host")
            echo "    FAIL: $host"
          fi
        }

        # --- Run selected checks --------------------------------------------------
        if [[ "$mode" == "flake-check" || "$mode" == "both" ]]; then
          echo ""
          echo ">>> Running: nix flake check  (evaluates all flake outputs — may be slow)"
          nix flake check "''${FLAKE_REF}" "''${DETERMINATE_OPTS[@]}" || echo "    flake check FAILED"
        fi

        if [[ "$mode" == "eval" || "$mode" == "both" ]]; then
          while IFS= read -r host; do
            do_eval "$host"
          done <<< "$selected"
        fi

        # --- Summary --------------------------------------------------------------
        echo ""
        echo "=== Summary ==="
        if [ "''${#passed[@]}" -gt 0 ]; then
          echo "PASSED: ''${passed[*]}"
        fi
        if [ "''${#failed[@]}" -gt 0 ]; then
          echo "FAILED: ''${failed[*]}"
          exit 1
        fi
        [ "''${#passed[@]}" -gt 0 ] && echo "All selected checks passed."
      '';
    };
  in {
    packages.nixos-check = nixos-check;
  };
}
