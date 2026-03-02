{inputs, withSystem, ...}: let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    config.permittedInsecurePackages = ["openssl-1.1.1w"];
    overlays = import ../../overlays;
  };
  pkgs-stable = import inputs.nixpkgs-stable {
    inherit system;
    config.allowUnfree = true;
  };
  lib = inputs.nixpkgs.lib;
  useHyprlandFlake = true;
  wrappedPkgs = withSystem system ({config, ...}: config.packages);
in {
  flake.nixosConfigurations.geks-zenbook = lib.nixosSystem {
    inherit system pkgs;
    modules =
      [
        inputs.determinate.nixosModules.default
        inputs.catppuccin.nixosModules.catppuccin
        inputs.sysc-greet.nixosModules.default
        ../../nixos/configurations/geks-zenbook/hardware-configuration-zenbook.nix
        ../../nixos/configurations/geks-zenbook/configuration-zenbook.nix
        ../../nixos/modules/geks-zenbook.nix
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-back";
            users.mykolas = {
              imports =
                [
                  inputs.catppuccin.homeModules.catppuccin
                  inputs.zen-browser.homeModules.beta
                  inputs.noctalia.homeModules.default
                  ../../home-manager/configurations/mykolas/home-zenbook.nix
                  ../../home-manager/modules/geks-zenbook.nix
                ]
                ++ lib.optionals useHyprlandFlake [
                  inputs.hyprland.homeManagerModules.default
                ];
              home.packages = [
                wrappedPkgs.kitty
                wrappedPkgs.ghostty
                wrappedPkgs.helix
                wrappedPkgs.tmux
                wrappedPkgs.wezterm
                wrappedPkgs.nix-update
                wrappedPkgs.nixos-build
              ];
            };
            extraSpecialArgs = {
              inherit inputs system pkgs-stable useHyprlandFlake wrappedPkgs;
              outputs = {};
            };
          };
        }
      ]
      ++ lib.optionals useHyprlandFlake [
        inputs.hyprland.nixosModules.default
      ];
    specialArgs = {
      inherit inputs pkgs-stable useHyprlandFlake wrappedPkgs;
      outputs = {};
    };
  };
}
