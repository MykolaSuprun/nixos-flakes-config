# Interactive ISO builder for NixOS configurations.
# Uses `nixos-rebuild build-image` (nixpkgs-native, replaces archived nixos-generators).
# Runs a dry-run config validation before committing to the full ISO build.
# vim-style keybindings: j/k=navigate, g/G=top/bottom, ctrl-d/u=half-page.
# WSL hosts are excluded (no meaningful installer ISO for WSL).
{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    nixos-iso = pkgs.writeShellApplication {
      name = "nixos-iso";
      runtimeInputs = [pkgs.jq pkgs.fzf pkgs.gnugrep pkgs.nixos-rebuild];
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

        # --- Host discovery (WSL excluded — no installer ISO makes sense for WSL) --
        installable_hosts=$(nix eval "''${FLAKE_REF}#nixosConfigurations" \
          --apply builtins.attrNames --json \
          --accept-flake-config 2>/dev/null \
          | jq -r '.[]' \
          | grep -iv wsl)

        if [ -z "$installable_hosts" ]; then
          echo "error: no installable nixosConfigurations found (WSL hosts are excluded)" >&2
          exit 1
        fi

        # --- Host selection -------------------------------------------------------
        host=$(echo "$installable_hosts" \
          | fzf \
              --header "Select target host (WSL hosts excluded):" \
              --prompt "host> " \
              "''${FZF_BIND[@]}") || { echo "Aborted." >&2; exit 1; }

        # --- Variant selection ----------------------------------------------------
        # iso-installer = graphical Calamares installer (nixos-rebuild build-image)
        # iso           = minimal live environment
        variant=$(printf "iso-installer\niso" \
          | fzf \
              --header "Select image variant:" \
              --prompt "variant> " \
              "''${FZF_BIND[@]}") || { echo "Aborted." >&2; exit 1; }

        echo ""
        echo "Host:    $host"
        echo "Variant: $variant"
        echo ""

        # --- Validation: dry-run config eval before the ISO build ----------------
        echo ">>> Validating '$host' config (dry-run)..."
        if ! nix build "''${FLAKE_REF}#nixosConfigurations.''${host}.config.system.build.toplevel" \
            --dry-run "''${DETERMINATE_OPTS[@]}"; then
          echo ""
          echo "ERROR: Config validation failed for '$host'. ISO build aborted." >&2
          exit 1
        fi
        echo ">>> Validation passed."
        echo ""

        # --- ISO build -----------------------------------------------------------
        echo ">>> Building $variant image for '$host'..."
        nixos-rebuild build-image \
          --image-variant "$variant" \
          --flake "''${FLAKE_REF}#''${host}" \
          "''${DETERMINATE_OPTS[@]}"

        iso_path=$(nix eval \
          "''${FLAKE_REF}#nixosConfigurations.''${host}.config.system.build.images.''${variant}.passthru.filePath" \
          --raw --accept-flake-config 2>/dev/null || true)
        echo ""
        echo "=== ISO build complete ==="
        if [ -n "$iso_path" ]; then
          echo "Output: $iso_path"
        else
          echo "Output: (run 'find result -name \"*.iso\"' to locate the image)"
        fi
      '';
    };
  in {
    packages.nixos-iso = nixos-iso;
  };
}
