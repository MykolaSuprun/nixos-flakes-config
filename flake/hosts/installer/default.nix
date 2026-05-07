# Minimal NixOS installer ISO.
# Contains the nixos-install script; boot from the USB and run:
#   nixos-install
# to interactively partition, format, and install the system.
#
# Build with: nix run .#nixos-iso
# Flash with: nix run .#nixos-flash -- ./result/iso/nixos-installer-*.iso
{
  inputs,
  withSystem,
  ...
}: let
  system = "x86_64-linux";
  lib = inputs.nixpkgs.lib;
  wrappedPkgs = withSystem system ({config, ...}: config.packages);
in {
  flake.nixosConfigurations.installer = lib.nixosSystem {
    inherit system;
    modules = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      {
        environment.systemPackages = [wrappedPkgs.nixos-install];
        # Faster squashfs compression (saves build time, larger image)
        isoImage.squashfsCompression = "zstd -Xcompression-level 6";
        isoImage.isoBaseName = lib.mkForce "nixos-installer";
      }
    ];
  };
}
