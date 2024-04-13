{
  description = "NixOS flake";

  nixConfig = {
    experimental-features = ["nix-command" "flakes"];
    allowUnfree = true;
    substituters = ["https://cache.nixos.org/"];
    extra-substituters = ["https://nix-community.cachix.org"];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    # nixos-wsl.url = "github:nix-community/NixOS-WSL";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      flake = true;
    };
    my-neovim = {
      url = "github:MykolaSuprun/nixvim-config";
      flake = true;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    nixos-wsl,
    my-neovim,
    ...
  } @ inputs: let
    inherit (self) outputs;
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = [
        "openssl-1.1.1w"
        "electron-25.9.0"
        "freeimage-unstable-2021-11-01"
        "nix-2.15.3"
      ];
      overlays =
        [
        ]
        ++ import ./overlays;
    };

    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = [
        "openssl-1.1.1w"
        "electron-25.9.0"
      ];
    };

    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      geks-nixos = lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/configurations/geks-nixos/hardware-configuration.nix
          ./nixos/configurations/geks-nixos/configuration.nix
          ./nixos/modules/nix-conf.nix
          ./nixos/modules/fonts.nix
          ./nixos/modules/pipewire.nix
          ./nixos/modules/input_method.nix
          ./nixos/modules/desktop-packages.nix
          # home-manager setup
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.mykolas = {
                imports = [
                  ./home-manager/configurations/mykolas/home-configuration.nix
                  ./home-manager/modules/geks-nixos.nix
                  ./home-manager/modules/shell.nix
                  ./home-manager/modules/chromium.nix
                  ./home-manager/modules/flatpak-overrides.nix
                  ./home-manager/modules/tmux.nix
                  ./home-manager/modules/dev-pkgs.nix
                  ./home-manager/modules/dektop-config.nix
                ];
              };
              extraSpecialArgs = {
                inherit
                  inputs
                  outputs
                  system
                  pkgs
                  pkgs-stable
                  my-neovim
                  ;
              };
            };
          }
        ];
        specialArgs = {inherit inputs outputs pkgs pkgs-stable my-neovim;};
      };
      geks-wsl = lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/configurations/geks-wsl/configuration.nix
          ./nixos/modules/nix-conf.nix
          # ./nixos/modules/fonts.nix
          nixos-wsl.nixosModules.wsl
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.mykolas = {
                imports = [
                  ./home-manager/configurations/mykolas/home-configuration.nix
                  ./home-manager/modules/geks-wsl.nix
                  ./home-manager/modules/shell.nix
                  ./home-manager/modules/tmux.nix
                  ./home-manager/modules/dev-pkgs.nix
                ];
              };
              extraSpecialArgs = {
                inherit
                  inputs
                  outputs
                  system
                  pkgs
                  pkgs-stable
                  my-neovim
                  ;
              };
            };
          }
        ];
        specialArgs = {inherit inputs outputs pkgs pkgs-stable my-neovim;};
      };
    };
  };
}
