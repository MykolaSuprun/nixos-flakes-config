{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
    home-manager.url = "https://github.com/nix-community/home-manager/archive/release-22.11.tar.gz";
    home-manager.inputs.nixpkgs.follows  = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ...}: 

  let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
    };

    lib = nixpkgs.lib; 

  in {
    nixosConfigurations = {
      Geks-Nixos = lib.nixosSystem {
        inherit system;

        modules = [
          ./system/configuration.nix
        ];
      };
    };

    homeConfigurations.mykolas = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      # Specify your home configuration modules here, for example,
      # the path to your home.nix.
      modules = [
        ./users/mykolas/home.nix
      ];

      # Optionally use extraSpecialArgs
      # to pass through arguments to home.nix
    };
  };
}
