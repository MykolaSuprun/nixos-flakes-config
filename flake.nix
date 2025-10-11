{
  description = "NixOS flake";

  nixConfig = {
    experimental-features = ["nix-command" "flakes"];
    allowUnfree = true;
    trusted-users = ["mykolas"];
    trusted-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      # "https://hyprland.cachix.org"
      "https://install.determinate.systems"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      # "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
    ];
  };

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      flake = true;
    };
    impurity.url = "github:outfoxxed/impurity.nix";
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # hyprland.url = "https://flakehub.com/f/hyprwm/Hyprland/0.51.1";
    # # hyprland.url = "github:hyprwm/Hyprland";
    # hyprland-plugins = {
    #   url = "github:hyprwm/hyprland-plugins?ref=v0.50.0";
    # url = "github:hyprwm/hyprland-plugins";
    #   inputs.hyprland.follows = "hyprland";
    # };
    # hy3 = {
    #   url = "github:outfoxxed/hy3?ref=hl0.51.0";
    #   # url = "github:outfoxxed/hy3";
    #   inputs.hyprland.follows = "hyprland";
    # };
    # pyprland = {
    #   url = "github:hyprland-community/pyprland";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # stylix = {
    #   url = "github:danth/stylix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    catppuccin.url = "github:catppuccin/nix";
    my-nixvim = {
      url = "git+ssh://git@github.com/MykolaSuprun/nixvim-config.git?ref=v2";
      flake = true;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    nixos-wsl,
    # stylix,
    ...
  } @ inputs: let
    inherit (self) outputs;
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = ["openssl-1.1.1w"];
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
    homeModules = {
      tmux = import ./home-manager/modules/tmux.nix;
      zellij = import ./home-manager/modules/zellij.nix;
      shell = import ./home-manager/modules/shell.nix;
    };

    nixosConfigurations = {
      geks-nixos = lib.nixosSystem {
        inherit system;
        inherit pkgs;
        modules = [
          inputs.determinate.nixosModules.default
          inputs.impurity.nixosModules.impurity
          # stylix.nixosModules.stylix
          inputs.catppuccin.nixosModules.catppuccin
          ./nixos/configurations/geks-nixos/hardware-configuration.nix
          ./nixos/configurations/geks-nixos/configuration.nix
          ./nixos/modules/geks-nixos.nix
          # home-manager setup
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-back";
              users.mykolas = {
                imports = [
                  # inputs.hyprland.homeManagerModules.default
                  # stylix.homeModules.stylix
                  inputs.catppuccin.homeModules.catppuccin
                  ./home-manager/configurations/mykolas/home-configuration.nix
                  ./home-manager/modules/geks-nixos.nix
                ];
              };
              extraSpecialArgs = {
                inherit inputs outputs system pkgs-stable;
              };
            };
          }
        ];
        specialArgs = {inherit inputs outputs pkgs-stable;};
      };
      geks-wsl = lib.nixosSystem {
        inherit system;
        inherit pkgs;
        modules = [
          inputs.determinate.nixosModules.default
          # stylix.nixosModules.stylix
          ./nixos/configurations/geks-wsl/configuration.nix
          ./nixos/modules/nix-conf.nix
          ./nixos/modules/sys-pkgs.nix
          inputs.catppuccin.nixosModules.catppuccin
          nixos-wsl.nixosModules.wsl
          home-manager.nixosModules.home-manager
          ./nixos/modules/catppuccin.nix
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-back";
              users.mykolas = {
                imports = [
                  inputs.catppuccin.homeModules.catppuccin
                  ./home-manager/configurations/mykolas/home-configuration.nix
                  ./home-manager/modules/geks-wsl.nix
                ];
              };
              extraSpecialArgs = {
                inherit inputs outputs system pkgs pkgs-stable;
              };
            };
          }
        ];
        specialArgs = {inherit inputs outputs pkgs-stable;};
      };
    };
  };
}
