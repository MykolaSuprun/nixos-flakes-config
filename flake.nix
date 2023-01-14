{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    home-manager.url =
      "https://github.com/nix-community/home-manager/archive/release-22.11.tar.gz";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    discord-overlay.url = "github:InternetUnexplorer/discord-overlay";
    discord-overlay.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, discord-overlay, ... }:

    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [
        ];
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [ 
          discord-overlay.overlays.default 
          (self: super: {
            steam = (super.steam.override {
              extraPkgs = pkgs-unstable: with pkgs-unstable; [ pango harfbuzz libthai ];
            });
          })
        ];
      };
      lib = nixpkgs.lib;

    in {
      nixosConfigurations = {
        Geks-Nixos = lib.nixosSystem {
          inherit system;
          modules = [ ./system/configuration.nix ];
        };
      };

      homeConfigurations.mykolas = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [ ./users/mykolas/home.nix ];
        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = { inherit pkgs-unstable; };
      };
    };
}
