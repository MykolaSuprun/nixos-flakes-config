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
      rm -f ~/.gtkrc-2.0.hm-back
      rm -f ~/.config/gtk-3.0/gtk.css
      rm -f ~/.config/gtk-4.0/gtk.css.hm-back

      # Capture lock state before build
      lock_before=$(cat flake.lock)

      # Build with nh (flake keys come with --accept-flake-config; substituter
      # list single-sourced in cache.nix (repo root)
      nh os switch -- \
        --accept-flake-config --show-trace \
        --option extra-substituters "${builtins.concatStringsSep " " (import ../../cache.nix).trusted-substituters}" \
        --option extra-trusted-public-keys "${builtins.concatStringsSep " " (import ../../cache.nix).trusted-public-keys}"

      # Get current generation number
      gen=$(sudo nix-env -p /nix/var/nix/profiles/system --list-generations | grep current | ${pkgs.gawk}/bin/awk '{print $1}')

      # Detect updated inputs from lock diff
      lock_after=$(cat flake.lock)
      updated_inputs=""
      if [ "$lock_before" != "$lock_after" ]; then
        # Compare only the per-node locked rev/url — avoids matching internal JSON
        # keys like "narHash", "lastModified", etc. that also change on updates.
        updated_inputs=$(${pkgs.diffutils}/bin/diff \
          <(echo "$lock_before" | ${pkgs.jq}/bin/jq -r '.nodes | to_entries[] | select(.key != "root") | [.key, (.value.locked.rev // .value.locked.url // "")] | join("=")' | ${pkgs.coreutils}/bin/sort) \
          <(echo "$lock_after"  | ${pkgs.jq}/bin/jq -r '.nodes | to_entries[] | select(.key != "root") | [.key, (.value.locked.rev // .value.locked.url // "")] | join("=")' | ${pkgs.coreutils}/bin/sort) \
          | ${pkgs.gnugrep}/bin/grep '^> ' | ${pkgs.gnused}/bin/sed 's/^> //' | ${pkgs.coreutils}/bin/cut -d= -f1 \
          | ${pkgs.coreutils}/bin/sort -u | ${pkgs.coreutils}/bin/tr '\n' ', ' | ${pkgs.gnused}/bin/sed 's/,$//')
      fi

      # Detect changed nix files
      changed_files=$(${pkgs.git}/bin/git diff --name-only HEAD -- '*.nix' 2>/dev/null | ${pkgs.coreutils}/bin/tr '\n' ', ' | ${pkgs.gnused}/bin/sed 's/,$//')

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
