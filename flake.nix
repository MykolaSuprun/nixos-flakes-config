{
  description = "NixOS flake";

  nixConfig = {
    experimental-features = ["nix-command" "flakes"];
    allowUnfree = true;
    substituters = [
      "https://cache.nixos.org/"
      "https://hyprland.cachix.org"
      "https://anyrun.cachix.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
    extra-substituters = ["https://nix-community.cachix.org"];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
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
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      flake = true;
    };
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      # url = "git+https://github.com/hyprwm/Hyprland?submodules=1?ref=v0.40.0";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hy3 = {
      url = "github:outfoxxed/hy3"; # where {version} is the hyprland release version
      # url = "github:outfoxxed/hy3?ref=hl0.40.0"; # where {version} is the hyprland release version
      # or "github:outfoxxed/hy3" to follow the development branch.
      # (you may encounter issues if you dont do the same for hyprland)
      inputs.hyprland.follows = "hyprland";
    };
    anyrun = {
      url = "github:Kirottu/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    my-neovim = {
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
    hyprland,
    hyprland-plugins,
    hy3,
    anyrun,
    catppuccin,
    my-neovim,
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
        "freeimage-unstable-2021-11-01"
        "nix-2.15.3"
      ];
      overlays =
        [
          # (self: super: {
          #   vmware-workstation = super.vmware-workstation.overrideAttrs (vself: vsuper: let
          #     urlBase = "https://softwareupdate.vmware.com/cds/vmw-desktop/ws/${vself.version}/${vself.build}/linux/";
          #     file = "VMware-Workstation-${vself.version}-${vself.build}.x86_64.bundle";
          #   in {
          #     src = "${self.fetchzip {
          #       url = urlBase + "core/${file}.tar";
          #       hash = "sha256-nYkqZ7w3AYdw2YvQNATIYeJpqUwmkLE6jzyQlhGKyEs=";
          #       stripRoot = false;
          #     }}/${file}";
          #     unpackPhase = let
          #       vmware-unpack-env = self.buildFHSEnv {
          #         name = "vmware-unpack-env";
          #         targetPkgs = pkgs: [self.zlib];
          #       };
          #       vmware-tools = let
          #         version = "12.3.5";
          #         build = "22544099";
          #         file = system: "vmware-tools-${system}-${version}-${build}.x86_64.component";
          #         hashes = {
          #           linux = "sha256-VHFc2g9Bpz7RaJDTB+MXZ2VKe6YfcM1Y2qcqL75mOgw=";
          #           linuxPreGlibc25 = "sha256-ubxS82tyY/biGSBPvPFsggKLYRXUMVJU9dqNfILa7OY=";
          #           netware = "sha256-Fs+R4RTgbV+SlFuz7DO/NXdqfMMXf05eSmIfD8AWjvI=";
          #           solaris = "sha256-HajtvDG/iPUmi7clO2wkSQRMWsOI/rLFHVDlw/vL4wI=";
          #           winPre2k = "sha256-lX4uvJRFSUIzm6cxCCuZwrsgPuRE2Wr1+GYFY0Qk8Tw=";
          #           winPreVista = "sha256-xA3UvxIS7u435T0LsyMTCHFUZL9dkTXuekXexOWkXRc=";
          #           windows = "sha256-/UrzEQTBhmuQODnNoNPQD4pI4MNCxordb/FxVPS3A9o=";
          #         };
          #         srcs = map (
          #           system: "${self.fetchzip {
          #             url = urlBase + "packages/${file system}.tar";
          #             hash = hashes.${system};
          #             stripRoot = false;
          #           }}/${file system}"
          #         ) (builtins.attrNames hashes);
          #       in
          #         lib.concatMapStringsSep " " (src: "--install-component ${src}") srcs;
          #     in ''
          #       ${vmware-unpack-env}/bin/vmware-unpack-env -c "sh ${vself.src} ${vmware-tools} --extract unpacked"
          #     '';
          #   });
          # })
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

    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      geks-nixos = lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/configurations/geks-nixos/hardware-configuration.nix
          ./nixos/configurations/geks-nixos/configuration.nix
          ./nixos/modules/nix-conf.nix
          ./nixos/modules/fonts.nix
          ./nixos/modules/pipewire.nix
          ./nixos/modules/sys-pkgs.nix
          ./nixos/modules/desktop-pkgs.nix
          catppuccin.nixosModules.catppuccin
          # home-manager setup
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.mykolas = {
                imports = [
                  ./home-manager/configurations/mykolas/home-configuration.nix
                  ./home-manager/modules/geks-nixos.nix
                  ./home-manager/modules/input_method.nix
                  ./home-manager/modules/shell.nix
                  ./home-manager/modules/chromium.nix
                  ./home-manager/modules/flatpak-overrides.nix
                  ./home-manager/modules/tmux.nix
                  ./home-manager/modules/dev-pkgs.nix
                  ./home-manager/modules/dektop-config.nix
                  hyprland.homeManagerModules.default
                  ./home-manager/modules/hyprland.nix
                  anyrun.homeManagerModules.default
                  catppuccin.homeManagerModules.catppuccin
                ];
              };
              extraSpecialArgs = {
                inherit
                  inputs
                  outputs
                  system
                  pkgs
                  pkgs-stable
                  hyprland
                  hyprland-plugins
                  hy3
                  anyrun
                  my-neovim
                  ;
              };
            };
          }
        ];
        specialArgs = {inherit inputs outputs pkgs pkgs-stable hyprland my-neovim;};
      };
      geks-wsl = lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/configurations/geks-wsl/configuration.nix
          ./nixos/modules/nix-conf.nix
          ./nixos/modules/sys-pkgs.nix
          catppuccin.nixosModules.catppuccin
          # ./nixos/modules/fonts.nix
          nixos-wsl.nixosModules.wsl
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.mykolas = {
                imports = [
                  ./home-manager/configurations/mykolas/home-configuration.nix
                  ./home-manager/modules/geks-wsl.nix
                  ./home-manager/modules/shell.nix
                  ./home-manager/modules/tmux.nix
                  ./home-manager/modules/dev-pkgs.nix
                  catppuccin.homeManagerModules.catppuccin
                ];
              };
              extraSpecialArgs = {
                inherit
                  inputs
                  outputs
                  system
                  pkgs
                  pkgs-stable
                  my-neovim
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
