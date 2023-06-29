{
  description = "NixOS flake";

   nixConfig = {
    experimental-features = [ "nix-command" "flakes" ];
    allowUnfree = true;
    substituters = [
      "https://cache.nixos.org/"
    ];
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-unstable";
    };
    nixpkgs-stable = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-23.05";
    };
    home-manager = {
      type = "github";
      owner = "nix-community";
      repo = "home-manager";
      ref = "master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = inputs@{self, nixpkgs, nixpkgs-stable, home-manager, ...}:
  let
    inherit (self) outputs;
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
    };

    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config = { allowUnfree = true; };
    };

    lib = nixpkgs.lib;

  in
  rec {
    nixosModules = [
      ./modules/nixos/pipewire.nix 
      ./modules/nixos/input_method.nix
      ./modules/nixos/fonts.nix
    ];

    homeManagerModules = [
      ./modules/home-manager/default-shell.nix
      ./modules/home-manager/chromium.nix
      ./modules/home-manager/flatpak-overrides.nix
      ./modules/home-manager/neovim.nix
    ];

    nixosConfigurations = {
      Geks-Nixos = lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/configuration.nix
       ];
        specialArgs = { inherit inputs outputs; };
      };
    };

    homeConfigurations = {
      mykolas = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ 
          ./home/mykolas/home.nix
        ];
        extraSpecialArgs = { inherit inputs outputs; };
      };
    };
  };
}
