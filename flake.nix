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
    nixgl.url = "github:guibou/nixGL";
    my-neovim = {
      url = "github:MykolaSuprun/neovim-flake";
      flake = true;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    nixgl,
    my-neovim,
    # plasma6,
    ...
  } @ inputs: let
    inherit (self) outputs;
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "openssl-1.1.1w"
          "electron-25.9.0"
        ];
      };
      # overlays = [
      #   nixgl.overlay
      # ];
    };

    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "openssl-1.1.1w"
          "electron-25.9.0"
        ];
      };
      # overlays = [
      #   nixgl.overlay
      # ];
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
              extraSpecialArgs = {inherit inputs outputs pkgs pkgs-stable my-neovim system;};
            };
          }
          # overlays
          (args: { nixpkgs.overlays = import ./overlays args; })
        ];
        specialArgs = {inherit inputs outputs pkgs pkgs-stable my-neovim;};
      };
    };
  };
}
