# Minimal NixOS installer ISO.
# Contains the nixos-install script, nixvim, and tmux; boot from the USB and run:
#   nixos-install
# to interactively partition, format, and install the system.
#
# The ISO bundles, per installable host:
#   - system toplevel  (nixos-install copies this to the target store)
#   - disko format+mount script  (pre-built with /dev/nvme0n1; patched at runtime)
# Installation is fully offline — no nix evaluations or network access needed.
# Requires a 32 GB+ USB.
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

  # Pre-built system toplevels for every installable host.
  nixosSystems = lib.genAttrs ["geks-nixos" "geks-zenbook"]
    (host: inputs.self.nixosConfigurations.${host}.config.system.build.toplevel);

  # Pre-built disko format+mount scripts.
  # device = "/dev/null" (the lib.mkDefault) would abort during evaluation
  # because disko's deviceNumbering function can't derive partition names for it.
  # We override to /dev/nvme0n1 — the standard NVMe device name on both machines.
  # nixos-install patches the device path at install time via sed, so any disk
  # can be targeted without re-evaluation.
  nixosDiskoScripts = lib.genAttrs ["geks-nixos" "geks-zenbook"]
    (host:
      (inputs.self.nixosConfigurations.${host}.extendModules {
        modules = [{ disko.devices.disk.main.device = lib.mkForce "/dev/nvme0n1"; }];
      }).config.system.build.diskoScript);
in {
  flake.nixosConfigurations.installer = lib.nixosSystem {
    inherit system;
    modules = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      {
        nix.settings = {
          experimental-features = [ "nix-command" "flakes" ];
          # Suppress Determinate Nix interactive trust prompts for both users.
          trusted-users = [ "root" "nixos" ];
        };

        environment.systemPackages = [
          wrappedPkgs.nixos-install
          wrappedPkgs.tmux
          inputs.my-nixvim.packages.${system}.nvim
        ];

        environment.etc."nixos/README.md".source = inputs.self + "/README.md";

        # Pre-built systems manifest:
        # { "host": { "system": "/nix/store/...", "diskoScript": "/nix/store/..." } }
        # nixos-install reads this at install time — zero nix invocations needed.
        environment.etc."nixos-installer-systems.json".text =
          builtins.toJSON (lib.mapAttrs (host: sys: {
            system = "${sys}";
            diskoScript = "${nixosDiskoScripts.${host}}";
          }) nixosSystems);

        # isoImage.storeContents traces the RUNTIME closure of each listed path,
        # so all transitive store dependencies are automatically included.
        isoImage.storeContents =
          lib.attrValues nixosSystems
          ++ lib.attrValues nixosDiskoScripts;

        isoImage.squashfsCompression = "zstd -Xcompression-level 19";
        isoImage.isoBaseName = lib.mkForce "nixos-installer";
      }
    ];
  };
}
