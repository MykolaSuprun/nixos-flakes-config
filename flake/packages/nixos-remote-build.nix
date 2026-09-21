# Rebuild the running NixOS system from the published flake.
# Useful when the local checkout is unavailable or you want a clean remote build.
# Set FLAKE_REF=. to use the local tree instead (must be committed).
# vim-style keybindings: j/k=navigate, g/G=top/bottom, ctrl-d/u=half-page.
{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    nixos-remote-build = pkgs.writeShellApplication {
      name = "nixos-remote-build";
      runtimeInputs = [pkgs.fzf pkgs.jq pkgs.nixos-rebuild pkgs.nix];
      text = ''
        # Set FLAKE_REF=. to use a local checkout instead of the public flake.
        FLAKE_REF="''${FLAKE_REF:-gitlab:mykolas-open/nixos-flakes-config}"

        # Binary-substituter flags; list single-sourced in cache.nix (repo root).
        DETERMINATE_OPTS=(
          --accept-flake-config
          --show-trace
          --option extra-substituters "${builtins.concatStringsSep " " (import ../../cache.nix).trusted-substituters}"
          --option extra-trusted-public-keys "${builtins.concatStringsSep " " (import ../../cache.nix).trusted-public-keys}"
        )

        FZF_BIND=(--bind "j:down,k:up,g:first,G:last,ctrl-d:half-page-down,ctrl-u:half-page-up")

        # --- Host selection -------------------------------------------------------
        all_hosts=$(nix eval "''${FLAKE_REF}#nixosConfigurations" \
          --apply builtins.attrNames --json \
          "''${DETERMINATE_OPTS[@]}" 2>/dev/null \
          | jq -r '.[]')

        host=$(echo "$all_hosts" \
          | fzf \
              --header "Select host to build:" \
              --prompt "host> " \
              "''${FZF_BIND[@]}") || { echo "Aborted." >&2; exit 1; }

        # --- Action selection -----------------------------------------------------
        action=$(printf "switch\nboot\ntest\ndry-activate" \
          | fzf \
              --header "Select nixos-rebuild action:" \
              --prompt "action> " \
              "''${FZF_BIND[@]}") || { echo "Aborted." >&2; exit 1; }

        echo ""
        echo "Host:   $host"
        echo "Action: $action"
        echo "Flake:  $FLAKE_REF"
        echo ""

        sudo nixos-rebuild "$action" \
          --flake "''${FLAKE_REF}#''${host}" \
          "''${DETERMINATE_OPTS[@]}"
      '';
    };
  in {
    packages.nixos-remote-build = nixos-remote-build;
  };
}
