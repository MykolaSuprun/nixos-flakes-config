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
    # determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    determinate.url = "github:DeterminateSystems/determinate/custom-conf";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    # nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2405.*.tar.gz";
    home-manager = {
      # url = "https://flakehub.com/f/nix-community/home-manager/0.1.0.tar.gz";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      flake = true;
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # hyprland.url =
    #   "git+https://github.com/hyprwm/Hyprland?submodules=1&ref=refs/tags/v0.47.2";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      # url = "github:hyprwm/hyprland-plugins?ref=v0.47.0";
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    # hy3 = {
    #   url = "github:outfoxxed/hy3?ref=hl0.47.0-1";
    #   # url = "github:outfoxxed/hy3";
    #   inputs.hyprland.follows = "hyprland";
    # };
    # pyprland = {
    #   url = "github:hyprland-community/pyprland";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    catppuccin.url = "github:catppuccin/nix";
    my-neovim = {
      url = "git+ssh://git@github.com/MykolaSuprun/neovim-nvf-config.git?ref=main";
      flake = true;
    };
  };

  outputs = {
    self,
    determinate,
    nixpkgs,
    nixpkgs-stable,
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
      overlays =
        [
          # (final: prev: {
          #   pyprland = inputs.pyprland.packages.${system}.pyprland;
          # })
        ]
        ++ import ./overlays;
    };

    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = [];
    };

    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      geks-nixos = lib.nixosSystem {
        inherit system;
        inherit pkgs;
        modules = [
          determinate.nixosModules.default
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
              backupFileExtension = "home-backup";
              users.mykolas = {
                imports = [
                  # inputs.hyprland.homeManagerModules.default
                  catppuccin.homeModules.catppuccin
                  ./home-manager/configurations/mykolas/home-configuration.nix
                  ./home-manager/modules/geks-nixos.nix
                ];
              };
              extraSpecialArgs = {
                inherit inputs outputs system pkgs-stable my-neovim;
              };
            };
          }
        ];
        specialArgs = {inherit inputs outputs pkgs-stable my-neovim;};
      };
      geks-wsl = lib.nixosSystem {
        inherit system;
        inherit pkgs;
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
              backupFileExtension = "home-backup";
              users.mykolas = {
                imports = [
                  catppuccin.homeModules.catppuccin
                  ./home-manager/configurations/mykolas/home-configuration.nix
                  ./home-manager/modules/geks-wsl.nix
                ];
              };
              extraSpecialArgs = {
                inherit inputs outputs system pkgs pkgs-stable my-neovim;
              };
            };
          }
        ];
        specialArgs = {inherit inputs outputs pkgs-stable my-neovim;};
      };
    };
    # homeConfigurations = {
    #   mykolas = home-manager.lib.homeManagerConfiguration {
    #     inherit pkgs;
    #     modules = [
    #       # inputs.hyprland.homeManagerModules.default
    #       catppuccin.homeModules.catppuccin
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
