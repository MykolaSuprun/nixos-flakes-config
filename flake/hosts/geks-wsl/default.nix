# Flake-parts host module for geks-wsl (WSL2, minimal environment).
{
  inputs,
  withSystem,
  ...
}: let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = import ../../../overlays;
  };
  pkgs-stable = import inputs.nixpkgs-stable {
    inherit system;
    config.allowUnfree = true;
  };
  lib = inputs.nixpkgs.lib;
  wrappedPkgs = withSystem system ({config, ...}: config.packages);
in {
  flake.nixosConfigurations.geks-wsl = lib.nixosSystem {
    inherit system pkgs;
    modules = [
      inputs.determinate.nixosModules.default
      inputs.catppuccin.nixosModules.catppuccin
      inputs.nixos-wsl.nixosModules.wsl
      ./_configuration.nix
      # NixOS feature modules used by WSL
      ../../../nixos/catppuccin.nix
      ../../../nixos/nix-conf.nix
      ../../../nixos/sys-pkgs.nix
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-back";
          users.mykolas = {
            imports = [
              inputs.catppuccin.homeModules.catppuccin
              ../../../home-manager/users/mykolas/home-wsl.nix
              # HM feature modules used by WSL
              ../../../home-manager/modules/catppuccin.nix
              ../../../home-manager/modules/dev-pkgs.nix
              ../../../home-manager/modules/shell.nix
            ];
            home.packages = [
              wrappedPkgs.helix
              wrappedPkgs.tmux
              wrappedPkgs.nix-update
            ];
          };
          extraSpecialArgs = {
            inherit inputs system pkgs pkgs-stable wrappedPkgs;
            outputs = {};
          };
        };
      }
    ];
    specialArgs = {
      inherit inputs pkgs-stable wrappedPkgs;
      outputs = {};
    };
  };
}
