{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    nixos-build = pkgs.writeShellScriptBin "nixos-build" ''
      set -euo pipefail
      FLAKE_DIR="''${NIXOS_CONF_DIR:-$HOME/workspaces/src/nixconf}"
      cd "$FLAKE_DIR"

      # Clean up known hm-back files
      rm -f ~/.config/hypr/hyprland.conf.hm-back
      rm -f ~/.config/ghostty/config.hm-back

      # Capture lock state before build
      lock_before=$(cat flake.lock)

      # Build with nh
      nh os switch -- \
        --accept-flake-config --show-trace \
        --option extra-substituters https://install.determinate.systems \
        --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=

      # Get current generation number
      gen=$(sudo nix-env -p /nix/var/nix/profiles/system --list-generations | grep current | ${pkgs.gawk}/bin/awk '{print $1}')

      # Detect updated inputs from lock diff
      lock_after=$(cat flake.lock)
      updated_inputs=""
      if [ "$lock_before" != "$lock_after" ]; then
        updated_inputs=$(diff <(echo "$lock_before") <(echo "$lock_after") \
          | ${pkgs.gnugrep}/bin/grep -oP '"[a-zA-Z0-9_-]+":' \
          | sort -u \
          | ${pkgs.gnused}/bin/sed 's/"//g; s/://g' \
          | tr '\n' ', ' \
          | ${pkgs.gnused}/bin/sed 's/,$//')
      fi

      # Detect changed nix files
      changed_files=$(${pkgs.git}/bin/git diff --name-only HEAD -- '*.nix' 2>/dev/null | tr '\n' ', ' | ${pkgs.gnused}/bin/sed 's/,$//')

      # Build commit message
      msg="gen $gen"
      if [ -n "$updated_inputs" ]; then
        msg="$msg: updated [$updated_inputs]"
      fi
      if [ -n "$changed_files" ]; then
        msg="$msg; changed [$changed_files]"
      fi

      ${pkgs.git}/bin/git add -A
      ${pkgs.git}/bin/git commit -am "$msg" || echo "Nothing to commit"

      # Reload Hyprland if running
      if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE+set}" ]; then
        hyprctl reload || true
      fi

      echo "Build complete: $msg"
    '';
  in {
    packages.nixos-build = nixos-build;
  };
}
