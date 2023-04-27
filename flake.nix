{
  description = "System configuration";

  inputs = {
    nixpkgs-stable.url = "nixpkgs/nixos-22.11";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url =
      "https://github.com/nix-community/home-manager/archive/master.tar.gz";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (self) outputs;
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };

      pkgs-stable = import inputs.nixpkgs-stable {
        inherit system;
        config = { allowUnfree = true; };
      };

      lib = nixpkgs.lib;


    in {


      # Packages and modifications, exported as overlays
      overlays = { 
        stable = (import ./overlays/stable.nix { inherit inputs; }).stable-packages;
        home_modifications = (import ./overlays/modifications.nix { inherit inputs outputs pkgs pkgs-stable; }).home_modifications;
        additions = (import ./overlays/modifications.nix { inherit inputs outputs pkgs pkgs-stable; }).additions;
      };
      # overlays = [
      #  import ./overlays/stable.nix { inherit inputs; }
      #  import ./overlays/modifications.nix { inherit inputs; }
      # ];
      # Nixos modules you might want to export
      nixosModules = map import [
        ./modules/nixos/pipewire.nix 
        ./modules/nixos/input_method.nix
        ./modules/nixos/fonts.nix
      ];
      # Home-manager modules you might want to export
      homeManagerModules = map import [
        ./modules/home-manager/default-shell.nix
        ./modules/home-manager/chromium.nix
        ./modules/home-manager/flatpak-overrides.nix 
      ];

      nixosConfigurations = {
        Geks-Nixos = lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs outputs; };
          modules = [ ./nixos/configuration.nix ];
        };
      };

      homeConfigurations = {
        mykolas = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [ ./users/mykolas/home.nix ];
          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
          extraSpecialArgs = { inherit inputs outputs; };
        };

        geks-home = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [ ./users/geks-home/home.nix ];
          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
          extraSpecialArgs = { inherit inputs outputs; };
        };
      };
    };
}
