# Host builder (dendritic). Every NixOS / Home Manager feature in this repo is
# a flake-parts module that contributes to `flake.modules.nixos.<aspect>` and/or
# `flake.modules.homeManager.<aspect>`. Each host imports ALL aspects; what is
# actually active is decided by the `myconf.*` / `hyprconf.*` enable flags set
# in the host's own modules.
#
# A host is declared by contributing to `configurations.nixos.<name>`:
#   module  — host-only NixOS config (hardware, disks, enable flags, ...)
#   home    — host-only Home Manager config for the primary user
# Several files may contribute to the same host; deferred modules merge.
{
  inputs,
  config,
  lib,
  ...
}: let
  inherit (config.flake.modules) nixos homeManager;
  user = "mykolas";
in {
  imports = [inputs.flake-parts.flakeModules.modules];

  options.configurations.nixos = lib.mkOption {
    description = "NixOS hosts built from all feature aspects plus host modules.";
    default = {};
    type = lib.types.lazyAttrsOf (lib.types.submodule {
      options = {
        system = lib.mkOption {
          type = lib.types.str;
          default = "x86_64-linux";
        };
        module = lib.mkOption {
          type = lib.types.deferredModule;
          default = {};
        };
        home = lib.mkOption {
          type = lib.types.deferredModule;
          default = {};
        };
      };
    });
  };

  config.flake.nixosConfigurations =
    lib.mapAttrs (
      _name: host:
        inputs.nixpkgs.lib.nixosSystem {
          modules =
            builtins.attrValues nixos
            ++ [
              host.module
              inputs.home-manager.nixosModules.home-manager
              {
                nixpkgs = {
                  hostPlatform = host.system;
                  config.allowUnfree = true;
                  # Repo overlays first; hosts append their own.
                  overlays = lib.mkBefore [config.flake.overlays.default];
                };
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  backupFileExtension = "hm-back";
                  users.${user}.imports = builtins.attrValues homeManager ++ [host.home];
                };
              }
            ];
        }
    )
    config.configurations.nixos;
}
