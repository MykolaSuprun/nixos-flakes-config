# Builds the NixOS installer ISO (nixos-installer-*.iso).
# The ISO has nixos-install pre-installed — boot from the USB and run:
#   nixos-install
# to interactively partition, format, and install the system.
#
# Usage:
#   nixos-iso               # use FLAKE_REF env var, or auto-detect (local git repo → GitHub)
#   nixos-iso --local       # force local checkout (must be run from repo root or $NIXOS_CONF_DIR)
#   nixos-iso --github      # force GitHub (github:MykolaSuprun/nixos-flakes-config)
#   FLAKE_REF=. nixos-iso   # explicit override
{...}: {
  perSystem = {pkgs, ...}: let
    nixos-iso = pkgs.writeShellApplication {
      name = "nixos-iso";
      runtimeInputs = [pkgs.git];
      text = ''
        # --- Flake source resolution -----------------------------------------------
        # Explicit flags take precedence over $FLAKE_REF and auto-detection.
        _flag=""
        for arg in "$@"; do
          case "$arg" in
            --local)  _flag="local"  ;;
            --github) _flag="github" ;;
            *) echo "error: unknown argument: $arg" >&2; exit 1 ;;
          esac
        done

        if [ "$_flag" = "local" ]; then
          _local_dir="''${NIXOS_CONF_DIR:-$PWD}"
          if ! git -C "$_local_dir" rev-parse --git-dir &>/dev/null; then
            echo "error: --local requires a git repo at $_local_dir (set NIXOS_CONF_DIR if needed)" >&2
            exit 1
          fi
          FLAKE_REF="$_local_dir"
        elif [ "$_flag" = "github" ]; then
          FLAKE_REF="github:MykolaSuprun/nixos-flakes-config"
        elif [ -z "''${FLAKE_REF:-}" ]; then
          # Auto-detect: prefer local git repo, fall back to GitHub.
          _local_dir="''${NIXOS_CONF_DIR:-$PWD}"
          if git -C "$_local_dir" rev-parse --git-dir &>/dev/null; then
            FLAKE_REF="$_local_dir"
          else
            FLAKE_REF="github:MykolaSuprun/nixos-flakes-config"
          fi
        fi

        echo ">>> Building NixOS installer ISO from: $FLAKE_REF"
        echo "    (bundles all host closures — first build takes a long time)"
        echo ""

        nix build "''${FLAKE_REF}#nixosConfigurations.installer.config.system.build.isoImage" \
          --extra-experimental-features "nix-command flakes" \
          --accept-flake-config

        iso_file=$(find ./result/iso -name "*.iso" 2>/dev/null | head -1)
        echo ""
        echo "=== ISO ready ==="
        echo ""
        echo "Flash to USB:"
        if [ -n "$iso_file" ]; then
          echo "    nix run ''${FLAKE_REF}#nixos-flash -- $iso_file"
        else
          echo "    nix run ''${FLAKE_REF}#nixos-flash"
        fi
        echo ""
        echo "Boot from USB, then run:"
        echo "    nixos-install"
      '';
    };
  in {
    packages.nixos-iso = nixos-iso;
  };
}
