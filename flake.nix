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
      url = "github:0xc000022070/zen-browser-flake";
      # IMPORTANT: we're using "libgbm" and is only available in unstable so ensure
      # to have it up-to-date or simply don't specify the nixpkgs input
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # hyprland.url = "https://flakehub.com/f/hyprwm/Hyprland/0.51.1";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      # url = "github:hyprwm/hyprland-plugins?ref=v0.50.0";
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hy3 = {
      # url = "github:outfoxxed/hy3?ref=hl0.51.0";
      url = "github:outfoxxed/hy3";
      inputs.hyprland.follows = "hyprland";
    };
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

    hostConfigs = {
      geks-nixos = {
        useHyprlandFlake = true;
      };
      geks-zenbook = {
        useHyprlandFlake = true;
      };
      geks-wsl = {
        useHyprlandFlake = false;
      };
    };
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
        modules =
          [
            inputs.determinate.nixosModules.default
            # stylix.nixosModules.stylix
            inputs.catppuccin.nixosModules.catppuccin
            ./nixos/configurations/geks-nixos/hardware-configuration-geks-nixos.nix
            ./nixos/configurations/geks-nixos/configuration-geks-nixos.nix
            ./nixos/modules/geks-nixos.nix
            # home-manager setup
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-back";
                users.mykolas = {
                  imports =
                    [
                      # inputs.hyprland.homeManagerModules.default
                      # stylix.homeModules.stylix
                      inputs.catppuccin.homeModules.catppuccin
                      inputs.zen-browser.homeModules.beta
                      ./home-manager/configurations/mykolas/home-geks-nixos.nix
                      ./home-manager/modules/geks-nixos.nix
                    ]
                    ++ lib.optionals hostConfigs.geks-nixos.useHyprlandFlake [
                      inputs.hyprland.homeManagerModules.default
                    ];
                };
                extraSpecialArgs = {
                  inherit inputs outputs system pkgs-stable;
                  inherit (hostConfigs.geks-nixos) useHyprlandFlake;
                };
              };
            }
          ]
          ++ lib.optionals hostConfigs.geks-nixos.useHyprlandFlake [
            inputs.hyprland.nixosModules.default
          ];
        specialArgs = {
          inherit inputs outputs pkgs-stable;
          inherit (hostConfigs.geks-nixos) useHyprlandFlake;
        };
      };
      geks-zenbook = lib.nixosSystem {
        inherit system;
        inherit pkgs;
        modules =
          [
            inputs.determinate.nixosModules.default
            inputs.catppuccin.nixosModules.catppuccin
            ./nixos/configurations/geks-zenbook/hardware-configuration-zenbook.nix
            ./nixos/configurations/geks-zenbook/configuration-zenbook.nix
            ./nixos/modules/geks-zenbook.nix
            # home-manager setup
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-back";
                users.mykolas = {
                  imports =
                    [
                      # inputs.hyprland.homeManagerModules.default
                      # stylix.homeModules.stylix
                      inputs.catppuccin.homeModules.catppuccin
                      inputs.zen-browser.homeModules.beta
                      ./home-manager/configurations/mykolas/home-zenbook.nix
                      ./home-manager/modules/geks-zenbook.nix
                    ]
                    ++ lib.optionals hostConfigs.geks-zenbook.useHyprlandFlake [
                      inputs.hyprland.homeManagerModules.default
                    ];
                };
                extraSpecialArgs = {
                  inherit inputs outputs system pkgs-stable;
                  inherit (hostConfigs.geks-zenbook) useHyprlandFlake;
                };
              };
            }
          ]
          ++ lib.optionals hostConfigs.geks-zenbook.useHyprlandFlake [
            inputs.hyprland.nixosModules.default
          ];
        specialArgs = {
          inherit inputs outputs pkgs-stable;
          inherit (hostConfigs.geks-zenbook) useHyprlandFlake;
        };
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
