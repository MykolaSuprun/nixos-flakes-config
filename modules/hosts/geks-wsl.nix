{inputs, withSystem, ...}: let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = import ../../overlays;
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
      ../../nixos/configurations/geks-wsl/configuration.nix
      ../../nixos/modules/nix-conf.nix
      ../../nixos/modules/sys-pkgs.nix
      ../../nixos/modules/catppuccin.nix
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-back";
          users.mykolas = {
            imports = [
              inputs.catppuccin.homeModules.catppuccin
              ../../home-manager/configurations/mykolas/home-geks-wsl.nix
              ../../home-manager/modules/geks-wsl.nix
            ];
            home.packages = [
              wrappedPkgs.helix
              wrappedPkgs.tmux
              wrappedPkgs.nix-update
              wrappedPkgs.nixos-build
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
