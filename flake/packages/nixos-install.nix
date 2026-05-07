# Interactive one-command NixOS installer.
# Designed for use from the nixos-installer ISO (produced by nixos-iso) or a
# standard NixOS minimal ISO.
#
# Offline ISO path (boot from nixos-installer ISO):
#   - Host list and pre-built paths read from /etc/nixos-installer-systems.json
#   - Disk formatted/mounted by the pre-built disko script (device patched via sed)
#   - System closure copied to target by nixos-install --no-channel-copy
#   - Zero nix evaluations or network access required
#
# Online path (standard NixOS ISO):
#   - Binary caches written to nix.conf
#   - Host list fetched via nix eval
#   - Standard disko-install --flake
#
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
        pkgs.util-linux
        pkgs.coreutils
        pkgs.jq
        pkgs.git
        pkgs.nixos-install-tools
        disko-install
      ];
      text = ''
        # --- Mode detection -------------------------------------------------------
        # Offline mode: manifest exists on the nixos-installer ISO.
        OFFLINE=false
        if [ -f "/etc/nixos-installer-systems.json" ]; then
          OFFLINE=true
        fi

        # FLAKE_REF (online path only):
        #   1) $FLAKE_REF env var  (manual override)
        #   2) $NIXOS_CONF_DIR if it is a git repo
        #   3) $PWD if it is a git repo
        #   4) GitHub fallback
        if [ "$OFFLINE" = "false" ]; then
          if [ -z "''${FLAKE_REF:-}" ]; then
            if [ -n "''${NIXOS_CONF_DIR:-}" ] && git -C "$NIXOS_CONF_DIR" rev-parse --git-dir &>/dev/null; then
              FLAKE_REF="''${NIXOS_CONF_DIR}"
            elif git -C "$PWD" rev-parse --git-dir &>/dev/null; then
              FLAKE_REF="$PWD"
            else
              FLAKE_REF="github:MykolaSuprun/nixos-flakes-config"
            fi
          fi
          echo "Using flake: $FLAKE_REF"
        else
          echo "Mode: offline (pre-built closures from ISO — no network needed)"
        fi

        FZF_BIND=(--bind "j:down,k:up,g:first,G:last,ctrl-d:half-page-down,ctrl-u:half-page-up")

        # --- Configure Nix (online only) ------------------------------------------
        # On the offline ISO the live system has nix.settings pre-configured.
        # On a standard ISO write binary cache substituters.
        if [ "$OFFLINE" = "false" ]; then
          echo ">>> Configuring Nix binary caches..."
          mkdir -p ~/.config/nix
          cat <<EOF > ~/.config/nix/nix.conf
experimental-features = nix-command flakes
extra-substituters = https://cache.nixos.org https://nix-community.cachix.org https://install.determinate.systems
extra-trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkN8ET+NDs5/KznmBBmRQ= cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=
EOF
          sudo mkdir -p /root/.config/nix
          sudo cp ~/.config/nix/nix.conf /root/.config/nix/nix.conf
        fi

        # --- Host discovery -------------------------------------------------------
        echo ""
        if [ "$OFFLINE" = "true" ]; then
          # Read from the pre-built manifest — zero nix invocations needed.
          echo ">>> Reading hosts from ISO manifest..."
          installable_hosts=$(jq -r 'keys[]' /etc/nixos-installer-systems.json)
        else
          echo ">>> Fetching available hosts from flake..."
          installable_hosts=$(nix eval "''${FLAKE_REF}#nixosConfigurations" \
            --apply builtins.attrNames --json \
            --accept-flake-config \
            | jq -r '.[]' \
            | grep -Ev '\-wsl$|-iso$|^installer$')
        fi

        if [ -z "$installable_hosts" ]; then
          echo "error: no installable hosts found" >&2
          exit 1
        fi

        # --- Host selection -------------------------------------------------------
        host=$(echo "$installable_hosts" \
          | fzf \
              --header "Select host to install:" \
              --prompt "host> " \
              "''${FZF_BIND[@]}") || { echo "Aborted." >&2; exit 1; }

        # --- Disk selection -------------------------------------------------------
        disk=$(lsblk -dpno NAME,SIZE,MODEL \
          | grep -v "loop\|sr0" \
          | fzf \
              --header "Select installation disk — ALL DATA WILL BE ERASED:" \
              --prompt "disk> " \
              "''${FZF_BIND[@]}" \
          | awk '{print $1}') || { echo "Aborted." >&2; exit 1; }

        # --- Confirmation ---------------------------------------------------------
        echo ""
        echo "  Host:   $host"
        echo "  Disk:   $disk"
        if [ "$OFFLINE" = "false" ]; then
          echo "  Source: $FLAKE_REF"
        fi
        echo ""
        echo "  !! ALL DATA ON $disk WILL BE PERMANENTLY AND IRREVERSIBLY ERASED !!"
        echo ""
        read -r -p "Type 'yes' to continue, anything else to abort: " _confirm
        if [ "$_confirm" != "yes" ]; then
          echo "Aborted." >&2
          exit 1
        fi

        # --- Install --------------------------------------------------------------
        echo ""
        if [ "$OFFLINE" = "true" ]; then
          _system=$(jq -r --arg h "$host" '.[$h].system' /etc/nixos-installer-systems.json)
          _disko_script=$(jq -r --arg h "$host" '.[$h].diskoScript' /etc/nixos-installer-systems.json)

          # The pre-built disko script has /dev/nvme0n1 hardcoded as the disk
          # device (set via extendModules at ISO build time).  Patch it to the
          # actual disk selected above.
          #
          # NVMe/eMMC partitions use a 'p' prefix (e.g. nvme0n1p1), so a plain
          # prefix substitution covers both device and partition references.
          # SATA/virtio partitions have no 'p' (e.g. sda1), so we substitute
          # partition references explicitly before the bare device.
          _tmp_disko=$(mktemp --suffix=.sh)
          if [[ "$disk" =~ ^/dev/(nvme|mmcblk) ]]; then
            sed "s|/dev/nvme0n1|''${disk}|g" "$_disko_script" > "$_tmp_disko"
          else
            sed \
              "s|/dev/nvme0n1p1|''${disk}1|g; s|/dev/nvme0n1p2|''${disk}2|g; s|/dev/nvme0n1|''${disk}|g" \
              "$_disko_script" > "$_tmp_disko"
          fi

          echo ">>> Formatting and mounting $disk with disko..."
          DISKO_SKIP_SWAP=1 sudo bash "$_tmp_disko"
          rm "$_tmp_disko"

          echo ">>> Installing NixOS from pre-built closure..."
          # Resolve the absolute path within this script's runtimeInputs PATH
          # (where pkgs.nixos-install-tools comes first) before calling sudo,
          # which resets PATH and would otherwise find our own nixos-install script.
          _nixos_install_bin=$(command -v nixos-install)
          sudo "$_nixos_install_bin" \
            --no-channel-copy \
            --no-root-password \
            --system "$_system" \
            --root /mnt
        else
          sudo "$(command -v disko-install)" \
            --flake "''${FLAKE_REF}#''${host}" \
            --disk main "$disk" \
            --write-efi-boot-entries \
            --accept-flake-config
        fi
        
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
