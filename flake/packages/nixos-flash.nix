# Interactive ISO-to-USB flash tool.
# Uses fzf to pick an ISO file and a target block device, then writes
# it with dd.  Intended for flashing a downloaded NixOS minimal ISO before
# running nixos-install on the target machine.
#
# Usage:
#   nixos-flash                 # interactive ISO + device selection
#   nixos-flash /path/to.iso    # skip ISO picker, select device interactively
#
# vim-style keybindings: j/k=navigate, g/G=top/bottom, ctrl-d/u=half-page.
{...}: {
  perSystem = {pkgs, ...}: let
    nixos-flash = pkgs.writeShellApplication {
      name = "nixos-flash";
      runtimeInputs = [pkgs.fzf pkgs.util-linux pkgs.coreutils pkgs.gnugrep pkgs.gawk pkgs.pv];
      text = ''
        FZF_BIND=(--bind "j:down,k:up,g:first,G:last,ctrl-d:half-page-down,ctrl-u:half-page-up")

        # --- ISO selection -------------------------------------------------------
        # Accept an explicit path as $1, otherwise search ~/Downloads and CWD.
        if [ $# -ge 1 ]; then
          ISO="$1"
        else
          iso_candidates=""
          for search_dir in "$HOME/Downloads" "."; do
            if [ -d "$search_dir" ]; then
              found=$(find "$search_dir" -maxdepth 1 -name "*.iso" 2>/dev/null | sort)
              [ -n "$found" ] && iso_candidates="$iso_candidates"$'\n'"$found"
            fi
          done
          # Strip leading blank line and deduplicate.
          iso_candidates=$(echo "$iso_candidates" | grep -v '^$' | sort -u)

          if [ -n "$iso_candidates" ]; then
            ISO=$(echo "$iso_candidates" \
              | fzf \
                  --header "Select ISO file (or press Esc to enter path manually):" \
                  --prompt "iso> " \
                  "''${FZF_BIND[@]}") || ISO=""
          fi

          if [ -z "''${ISO:-}" ]; then
            read -r -p "Enter path to ISO file: " ISO
          fi
        fi

        if [ ! -f "$ISO" ]; then
          echo "error: ISO file not found: $ISO" >&2
          exit 1
        fi

        ISO=$(realpath "$ISO")

        # --- Device selection ----------------------------------------------------
        # Show only USB block devices (TRAN=usb); fall back to all removable devices
        # if none are found via transport filter.
        # $NF is used for TRAN because model names may contain spaces, shifting columns.
        usb_devs=$(lsblk -dpno NAME,SIZE,MODEL,TRAN 2>/dev/null \
          | awk '$NF == "usb" {model=""; for(i=3;i<NF;i++) model=model (i>3?" ":"") $i; printf "%s  (%s) %s\n", $1, $2, model}')

        if [ -z "$usb_devs" ]; then
          # Fallback: show all non-loop, non-dm removable block devices
          usb_devs=$(lsblk -dpno NAME,SIZE,MODEL,RM 2>/dev/null \
            | awk '$1 !~ /^\/dev\/(loop|dm)/ && $NF == "1" {model=""; for(i=3;i<NF;i++) model=model (i>3?" ":"") $i; printf "%s  (%s) %s\n", $1, $2, model}')
        fi

        if [ -z "$usb_devs" ]; then
          echo "error: no USB / removable block devices detected." >&2
          echo "       Connect a USB drive and retry, or run:"  >&2
          echo "       lsblk -dpno NAME,SIZE,MODEL,TRAN" >&2
          exit 1
        fi

        device_line=$(echo "$usb_devs" \
          | fzf \
              --header "Select target USB device (DATA WILL BE ERASED):" \
              --prompt "device> " \
              "''${FZF_BIND[@]}") || { echo "Aborted." >&2; exit 1; }

        DEVICE=$(echo "$device_line" | awk '{print $1}')

        # --- Confirmation --------------------------------------------------------
        iso_size=$(du -sh "$ISO" | awk '{print $1}')
        echo ""
        echo "  ISO:    $ISO  ($iso_size)"
        echo "  Device: $DEVICE"
        echo ""
        echo "WARNING: ALL data on $DEVICE will be permanently destroyed."
        read -r -p "Type 'yes' to continue: " confirm

        if [ "$confirm" != "yes" ]; then
          echo "Aborted." >&2
          exit 1
        fi

        # --- Flash ---------------------------------------------------------------
        echo ""
        echo ">>> Flashing $ISO → $DEVICE ..."
        # pv runs as the current user (reads the ISO); sudo dd runs as root (writes the
        # device).  Piping between them avoids any quoting/injection risks from passing
        # a user-controlled path through sudo sh -c "...".
        pv -pterb "$ISO" | sudo dd of="$DEVICE" bs=4M oflag=sync
        sync
        echo ""
        echo ">>> Done. It is safe to remove the USB drive."
      '';
    };
  in {
    packages.nixos-flash = nixos-flash;
  };
}
