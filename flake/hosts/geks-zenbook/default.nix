# Flake-parts host module for geks-zenbook (Intel laptop, Hyprland).
# NixOS feature modules (nixos/*.nix) and HM feature modules
# (home-manager/modules/*.nix) are all imported here; each is gated by its
# own myconf.* / hyprconf.* enable flag set in configuration.nix / home-zenbook.nix.
{
  inputs,
  withSystem,
  ...
}: let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    config.permittedInsecurePackages = ["openssl-1.1.1w"];
    overlays = import ../../../overlays;
  };
  pkgs-stable = import inputs.nixpkgs-stable {
    inherit system;
    config.allowUnfree = true;
  };
  lib = inputs.nixpkgs.lib;
  useHyprlandFlake = true;
  wrappedPkgs = withSystem system ({config, ...}: config.packages);
in {
  flake.nixosConfigurations.geks-zenbook = lib.nixosSystem {
    inherit system pkgs;
    modules =
      [
        inputs.determinate.nixosModules.default
        inputs.catppuccin.nixosModules.catppuccin
        inputs.stylix.nixosModules.stylix
        inputs.sysc-greet.nixosModules.default
        inputs.disko.nixosModules.disko
        ./_disk-config.nix
        ./_hardware.nix
        ./_configuration.nix
        # NixOS feature modules (all gated by myconf.nixos.*.enable flags)
        ../../../nixos/catppuccin.nix
        ../../../nixos/desktop-config.nix
        ../../../nixos/flatpak.nix
        ../../../nixos/fonts.nix
        ../../../nixos/hyprland.nix
        ../../../nixos/input_method.nix
        ../../../nixos/nix-conf.nix
        ../../../nixos/pipewire.nix
        ../../../nixos/sys-pkgs.nix
        ../../../nixos/stylix.nix
        ../../../nixos/xdg.nix
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-back";
            users.mykolas = {
              imports =
                [
                  inputs.catppuccin.homeModules.catppuccin
                  inputs.zen-browser.homeModules.beta
                  inputs.noctalia.homeModules.default
                  ../../../home-manager/users/mykolas/home-zenbook.nix
                  # HM feature modules (all gated by myconf.*.enable flags)
                  ../../../home-manager/modules/catppuccin.nix
                  ../../../home-manager/modules/chromium.nix
                  ../../../home-manager/modules/desktop-config.nix
                  ../../../home-manager/modules/dev-pkgs.nix
                  ../../../home-manager/modules/fcitx5.nix
                  ../../../home-manager/modules/flatpak-overrides.nix
                  ../../../home-manager/modules/ghostty.nix
                  ../../../home-manager/modules/noctalia.nix
                  ../../../home-manager/modules/rofi.nix
                  ../../../home-manager/modules/shell.nix
                  ../../../home-manager/modules/stylix.nix
                  ../../../home-manager/modules/waybar.nix
                  ../../../home-manager/modules/zellij.nix
                  ../../../home-manager/modules/hyprland
                ]
                ++ lib.optionals useHyprlandFlake [
                  inputs.hyprland.homeManagerModules.default
                ];
              home.packages = [
                wrappedPkgs.kitty
                wrappedPkgs.helix
                wrappedPkgs.tmux
                wrappedPkgs.wezterm
                wrappedPkgs.nix-update
              ];
            };
            extraSpecialArgs = {
              inherit inputs system pkgs-stable useHyprlandFlake wrappedPkgs;
              outputs = {};
            };
          };
        }
      ]
      ++ lib.optionals useHyprlandFlake [
        inputs.hyprland.nixosModules.default
      ];
    specialArgs = {
      inherit inputs pkgs-stable useHyprlandFlake wrappedPkgs;
      outputs = {};
    };
  };
}
