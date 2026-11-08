# nixos-build — switch with nh, then commit the exact tree that was
# built as "gen N".
#
# Only TRACKED files are committed (`git add -u`): flakes cannot see untracked
# files, so anything the build used is already tracked or staged — untracked
# scratch files never sneak into the (publicly mirrored) history.
# A build with NIXOS_BUILD_EXTRA_ARGS (e.g. --override-input) is not
# reproducible from the commit, so it is not committed.
_: {
  perSystem = {pkgs, ...}: let
    cache = import ../../cache.nix;
  in {
    packages.nixos-build = pkgs.writeShellApplication {
      name = "nixos-build";
      runtimeInputs = with pkgs; [nh git jq diffutils coreutils gnused gnugrep];
      text = ''
        FLAKE_DIR="''${NIXOS_CONF_DIR:-$HOME/workspaces/src/nixconf}"
        cd "$FLAKE_DIR"

        # Stale Home Manager backups block the next activation.
        rm -f ~/.config/hypr/hyprland.conf.hm-back \
          ~/.gtkrc-2.0.hm-back \
          ~/.config/gtk-3.0/gtk.css.hm-back \
          ~/.config/gtk-4.0/gtk.css.hm-back

        lock_before=$(cat flake.lock)

        # Extra `nix build` args via NIXOS_BUILD_EXTRA_ARGS, e.g. to test an
        # unpushed input:
        #   NIXOS_BUILD_EXTRA_ARGS="--override-input herdr-vimnav path:../herdr-vimnav" nixos-build
        # The substituter flags only matter on fresh systems (installed hosts
        # already carry them in nix.conf); list single-sourced in cache.nix.
        # shellcheck disable=SC2086 # extra args are intentionally word-split
        nh os switch -- \
          --accept-flake-config --show-trace \
          ''${NIXOS_BUILD_EXTRA_ARGS:-} \
          --option extra-substituters "${builtins.concatStringsSep " " cache.trusted-substituters}" \
          --option extra-trusted-public-keys "${builtins.concatStringsSep " " cache.trusted-public-keys}"

        # /nix/var/nix/profiles/system -> system-N-link (no sudo needed).
        gen=$(readlink /nix/var/nix/profiles/system | sed -E 's/^system-([0-9]+)-link$/\1/')

        if [ -n "''${NIXOS_BUILD_EXTRA_ARGS:-}" ]; then
          echo "Build complete: gen $gen (NIXOS_BUILD_EXTRA_ARGS set — not committing)"
          exit 0
        fi

        # Inputs whose locked rev/url changed.
        lock_nodes() {
          jq -r '.nodes | to_entries[] | select(.key != "root")
            | [.key, (.value.locked.rev // .value.locked.url // "")] | join("=")' | sort
        }
        updated_inputs=""
        lock_after=$(cat flake.lock)
        if [ "$lock_before" != "$lock_after" ]; then
          updated_inputs=$(diff <(lock_nodes <<<"$lock_before") <(lock_nodes <<<"$lock_after") \
            | grep '^> ' | sed 's/^> //' | cut -d= -f1 | sort -u | paste -sd, - || true)
        fi

        git add -u
        changed_files=$(git diff --cached --name-only | paste -sd, - || true)

        msg="gen $gen"
        [ -n "$updated_inputs" ] && msg="$msg: updated [$updated_inputs]"
        [ -n "$changed_files" ] && msg="$msg; changed [$changed_files]"

        git commit -m "$msg" || echo "Nothing to commit"

        if untracked=$(git ls-files --others --exclude-standard) && [ -n "$untracked" ]; then
          echo "note: untracked files were NOT committed:" >&2
          printf '  %s\n' "$untracked" >&2
        fi

        echo "Build complete: $msg"
      '';
    };
  };
}
