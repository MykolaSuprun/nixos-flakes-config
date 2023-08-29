{
  system,
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  overlays,
  my-neovim,
  ...
}: {
  # imports = [./default-shell.nix];
  imports =
    [
      # If you want to use modules your own flake exports (from modules/home-manager):
      # outputs.homeManagerModules.example

      # Or modules exported from other flakes (such as nix-colors):
      # inputs.nix-colors.homeManagerModules.default

      # You can also split up your configuration and import pieces of it here:
      # ./nvim.nix

      ./../../modules/home-manager/default-shell.nix
      ./../../modules/home-manager/chromium.nix
      ./../../modules/home-manager/flatpak-overrides.nix
      ./../../modules/home-manager/tmux.nix
      ./../../modules/home-manager/dev-packages.nix
      ./../../modules/home-manager/wine-and-gaming-packages.nix
      ./../../modules/home-manager/dektop-packages.nix.nix
      #./modules/home-manager/firefox.nix
    ];

  nixpkgs = {
    # You can add overlays here
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;

      permittedInsecurePackages = ["openssl-1.1.1v"];
    };
  };

  home.username = "mykolas";
  home.homeDirectory = "/home/mykolas";

  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself.

  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "tty";
  };

  programs = {
    # enable home-manager
    home-manager.enable = true;
  };

  # create home configuration files
  home.file = {
    "./.config/helix" = {
      source = ./helix;
      recursive = true;
      enable = true;
    };
    "./.wezterm.lua" = {
      source = ./wezterm/wezterm.lua;
      enable = true;
    };
    "./.config/tmux.conf" = {
      source = ./tmux/tmux.conf;
      enable = true;
    };
    "./.gnupg/" = {
      source = ./gnupg;
      recursive = true;
      enable = true;
    };
    # "./.gitconfig" = {
    #   source = ./gitconfig/gitconfig;
    #   enable = true;
    # };
  };

  home.packages = with pkgs; [
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };
}
