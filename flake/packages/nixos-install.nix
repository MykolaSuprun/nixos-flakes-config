# Interactive one-command NixOS installer.
# Designed for use from a standard NixOS minimal ISO or the nixos-installer ISO
# produced by nixos-iso.
# Configures Nix caches, lets you pick host + disk via fzf, then runs disko-install.
# vim-style keybindings: j/k=navigate, g/G=top/bottom, ctrl-d/u=half-page.
{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    disko-install = inputs.disko.packages.${system}.disko-install;
    nixos-install = pkgs.writeShellApplication {
      name = "nixos-install";
      runtimeInputs = [
        pkgs.fzf
        pkgs.jq
        pkgs.git
        pkgs.util-linux
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.gawk
        disko-install
      ];
      text = ''
        # FLAKE_REF priority:
        #   1) $FLAKE_REF env var
        #   2) $NIXOS_CONF_DIR if it is a git repo
        #   3) $PWD if it is a git repo
        #   4) GitHub fallback
        if [ -z "''${FLAKE_REF:-}" ]; then
          if [ -n "''${NIXOS_CONF_DIR:-}" ] && git -C "$NIXOS_CONF_DIR" rev-parse --git-dir &>/dev/null; then
            FLAKE_REF="$NIXOS_CONF_DIR"
          elif git -C "$PWD" rev-parse --git-dir &>/dev/null; then
            FLAKE_REF="$PWD"
          else
            FLAKE_REF="github:MykolaSuprun/nixos-flakes-config"
          fi
        fi
        echo "Using flake: $FLAKE_REF"

        FZF_BIND=(--bind "j:down,k:up,g:first,G:last,ctrl-d:half-page-down,ctrl-u:half-page-up")

        # --- Configure binary caches -----------------------------------------------
        # NIX_CONFIG is read directly by nix — no /etc/nix/nix.conf write needed,
        # which would fail on the read-only NixOS live ISO.
        export NIX_CONFIG="extra-substituters = https://cache.nixos.org https://nix-community.cachix.org https://install.determinate.systems
extra-trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkN8ET+NDs5/KznmBBmRQ= cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
        echo ">>> Configured Nix binary caches via NIX_CONFIG."

        # --- Host discovery --------------------------------------------------------
        # Exclude WSL, -iso, and the installer host itself — not for hardware install
        installable_hosts=$(nix eval "''${FLAKE_REF}#nixosConfigurations" \
          --apply builtins.attrNames --json \
          --accept-flake-config 2>/dev/null \
          | jq -r '.[]' \
          | grep -Ev '\-wsl$|-iso$|^installer$')

        if [ -z "$installable_hosts" ]; then
          echo "error: no installable nixosConfigurations found" >&2
          exit 1
        fi

        # --- Host selection --------------------------------------------------------
        host=$(echo "$installable_hosts" \
          | fzf \
              --header "Select host to install:" \
              --prompt "host> " \
              "''${FZF_BIND[@]}") || { echo "Aborted." >&2; exit 1; }

        # --- Disk selection --------------------------------------------------------
        disk=$(lsblk -dpno NAME,SIZE,MODEL \
          | grep -v "loop\|sr0" \
          | fzf \
              --header "Select installation disk — ALL DATA WILL BE ERASED:" \
              --prompt "disk> " \
              "''${FZF_BIND[@]}" \
          | awk '{print $1}') || { echo "Aborted." >&2; exit 1; }

        # --- Confirmation ----------------------------------------------------------
        echo ""
        echo "  Host:   $host"
        echo "  Disk:   $disk"
        echo "  Source: $FLAKE_REF"
        echo ""
        echo "  !! ALL DATA ON $disk WILL BE PERMANENTLY AND IRREVERSIBLY ERASED !!"
        echo ""
        read -r -p "Type 'yes' to continue, anything else to abort: " _confirm
        if [ "$_confirm" != "yes" ]; then
          echo "Aborted." >&2
          exit 1
        fi

        # --- Install ---------------------------------------------------------------
        echo ""
        echo ">>> Running disko-install (this will take a while)..."
        # Resolve binary path before sudo — sudo resets PATH
        _disko_install=$(command -v disko-install)
        sudo "$_disko_install" \
          --flake "''${FLAKE_REF}#''${host}" \
          --disk main "$disk" \
          --write-efi-boot-entries \
          --accept-flake-config

        echo ""
        echo "============================="
        echo "  Installation complete!"
        echo "============================="
        echo ""
        echo "Next steps:"
        echo "  1. Reboot:           sudo reboot"
        echo "  2. Change passwords: passwd       (initial: nixos)"
        echo "                       sudo passwd  (initial: nixos)"
        if [ "$host" = "geks-zenbook" ]; then
          echo ""
          echo "  3. Enable hibernation (zenbook only — after first boot):"
          echo "       sudo btrfs inspect-internal map-swapfile -r /.swapvol/swapfile"
          echo "     Add the printed integer as:"
          echo "       boot.kernelParams = [ \"resume_offset=<N>\" ];"
          echo "     in flake/hosts/geks-zenbook/_configuration.nix, then: nixos-build"
        fi
      '';
    };
  in {
    packages.nixos-install = nixos-install;
  };
}
