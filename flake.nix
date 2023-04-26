{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    home-manager.url =
      "https://github.com/nix-community/home-manager/archive/release-22.11.tar.gz";
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

      pkgs-unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config = { allowUnfree = true; };
      };

      lib = nixpkgs.lib;


    in {


      # Packages and modifications, exported as overlays
      overlays = { 
        unstable = (import ./overlays/unstable.nix { inherit inputs; }).unstable-packages;
        home_modifications = (import ./overlays/modifications.nix { inherit inputs outputs pkgs pkgs-unstable; }).home_modifications;
        additions = (import ./overlays/modifications.nix { inherit inputs outputs pkgs pkgs-unstable; }).additions;
      };
      # overlays = [
      #  import ./overlays/unstable.nix { inherit inputs; }
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
