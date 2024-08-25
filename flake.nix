{
  description = "NixOS flake";

  nixConfig = {
    experimental-features = ["nix-command" "flakes"];
    allowUnfree = true;
    trusted-users = ["mykolas"];
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  inputs = {
    # nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2405.*.tar.gz";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    # nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2405.*.tar.gz";
    vbox-pinned.url = "github:NixOS/nixpkgs/nixos-24.05";
    # vbox-pinned.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2405.*.tar.gz";
    home-manager = {
      # url = "https://flakehub.com/f/nix-community/home-manager/0.2405.*.tar.gz";
      # url = "https://flakehub.com/f/nix-community/home-manager/0.1.0.tar.gz";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      flake = true;
    };
    # hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    # hyprland-plugins = {
    #   url = "github:hyprwm/hyprland-plugins";
    #   inputs.hyprland.follows = "hyprland";
    # };
    # hy3 = {
    #   url = "github:outfoxxed/hy3";
    #   inputs.hyprland.follows = "hyprland";
    # };
    catppuccin.url = "github:catppuccin/nix";
    my-neovim = {
      url = "github:MykolaSuprun/nixvim-config";
      flake = true;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    vbox-pinned,
    home-manager,
    nixos-wsl,
    catppuccin,
    my-neovim,
    ...
  } @ inputs: let
    inherit (self) outputs;
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = [
      ];
      overlays =
        []
        ++ import ./overlays;
    };

    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = [
      ];
    };

    pkgs-vbox = import vbox-pinned {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = [
      ];
    };

    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      geks-nixos = lib.nixosSystem {
        inherit system;
        modules = [
          catppuccin.nixosModules.catppuccin
          ./nixos/configurations/geks-nixos/hardware-configuration.nix
          ./nixos/configurations/geks-nixos/configuration.nix
          ./nixos/modules/geks-nixos.nix
          # home-manager setup
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.mykolas = {
                imports = [
                  # inputs.hyprland.homeManagerModules.default
                  catppuccin.homeManagerModules.catppuccin
                  ./home-manager/configurations/mykolas/home-configuration.nix
                  ./home-manager/modules/geks-nixos.nix
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
        specialArgs = {inherit inputs outputs pkgs pkgs-stable my-neovim pkgs-vbox;};
      };
      geks-wsl = lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/configurations/geks-wsl/configuration.nix
          ./nixos/modules/nix-conf.nix
          ./nixos/modules/sys-pkgs.nix
          catppuccin.nixosModules.catppuccin
          nixos-wsl.nixosModules.wsl
          home-manager.nixosModules.home-manager
          ./nixos/modules/catppuccin.nix
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.mykolas = {
                imports = [
                  catppuccin.homeManagerModules.catppuccin
                  ./home-manager/configurations/mykolas/home-configuration.nix
                  ./home-manager/modules/geks-wsl.nix
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
    # homeConfigurations = {
    #   mykolas = home-manager.lib.homeManagerConfiguration {
    #     inherit pkgs;
    #     modules = [
    #       # inputs.hyprland.homeManagerModules.default
    #       catppuccin.homeManagerModules.catppuccin
    #       ./home-manager/configurations/mykolas/home-configuration.nix
    #       ./home-manager/modules/geks-nixos.nix
    #     ];
    #     extraSpecialArgs = {
    #       inherit
    #         inputs
    #         outputs
    #         pkgs
    #         pkgs-stable
    #         my-neovim
    #         ;
    #     };
    #   };
    # };
  };
}
