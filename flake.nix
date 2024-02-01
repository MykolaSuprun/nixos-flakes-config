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
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    my-neovim = {
      url = "github:MykolaSuprun/nixvim-config";
      flake = true;
    };
    obsidian-libgl.url = "github:yshui/nixpkgs/obsidion-libgl";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    hyprland,
    my-neovim,
    obsidian-libgl,
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
    pkgs-obsidian-libgl = import obsidian-libgl {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = [
        "electron-25.9.0"
      ];
    };

    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      geks-nixos = lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/configurations/geks-nixos/configuration.nix
          # home-manager setup
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;

              users.mykolas = import ./home-manager/configurations/mykolas/home-configuration.nix;
              extraSpecialArgs = {
                inherit
                  inputs
                  outputs
                  system
                  pkgs
                  pkgs-stable
                  my-neovim
                  hyprland
                  pkgs-obsidian-libgl
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
