# Builds the NixOS installer ISO (nixos-installer-*.iso).
# The ISO has nixos-install pre-installed — boot from the USB and run:
#   nixos-install
# to interactively partition, format, and install the system.
# vim-style keybindings in nixos-install: j/k=navigate, g/G=top/bottom, ctrl-d/u=half-page.
{...}: {
  perSystem = {pkgs, ...}: let
    nixos-iso = pkgs.writeShellApplication {
      name = "nixos-iso";
      runtimeInputs = [];
      text = ''
        FLAKE_REF="''${FLAKE_REF:-github:MykolaSuprun/nixos-flakes-config}"

        echo ">>> Building NixOS installer ISO..."
        echo "    (first run may take a while — subsequent builds use the cache)"
        echo ""

        nix build "''${FLAKE_REF}#nixosConfigurations.installer.config.system.build.isoImage" \
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
