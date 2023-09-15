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
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    my-neovim = {
      url = "github:MykolaSuprun/neovim-flake";
      flake = true;
    };
    # nur = {
    #   url = "github:nix-community/NUR/master";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-stable,
    nixos-wsl,
    home-manager,
    my-neovim,
    ...
  }: let
    inherit (self) outputs;
    system = "x86_64-linux";

    # overlayMyNeovim = prev: final: {
    #   myNeovim = import my-neovim.packages.${system}.default {
    #     pkgs = final;
    #   };
    # };

    pkgs = import nixpkgs {
      inherit system;
      config = {allowUnfree = true;};
      # overlays = [overlayMyNeovim];
    };

    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config = {allowUnfree = true;};
    };

    lib = nixpkgs.lib;

    homeManagerOverlays = args: {nixpkgs.overlays = import ./overlays/home-manager args;};
  in {
    nixosConfigurations = {
      Geks-Nixos = lib.nixosSystem {
        inherit system;
        modules = [./nixos/geks-nixos/configuration.nix];
        specialArgs = {inherit inputs outputs;};
      };
      Geks-WSL = lib.nixosSystem {
        inherit system;
        modules = [./nixos/geks-wsl/configuration.nix nixos-wsl.nixosModules.wsl];
        specialArgs = {inherit inputs outputs;};
      };
    };

    homeConfigurations = {
      mykolas-nixos = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [./home/mykolas/mykolas-nixos.nix homeManagerOverlays];
        extraSpecialArgs = {inherit inputs outputs my-neovim system;};
      };
      mykolas-wsl = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [./home/mykolas/mykolas-wsl.nix homeManagerOverlays];
        extraSpecialArgs = {inherit inputs outputs my-neovim system;};
      };
      mykolas-wsl-generic = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [./home/mykolas/wsl-generic.nix homeManagerOverlays];
        extraSpecialArgs = {inherit inputs outputs my-neovim system;};
      };
    };
  };
}
