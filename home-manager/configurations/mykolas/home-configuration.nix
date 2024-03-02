{
  inputs,
  pkgs,
  ...
}: let
  hm_target = "mykolas-nixos";
  shell_hm_target = "export home_manager_target=${hm_target}";
in {
  # imports = [./default-shell.nix];
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix

    ./../../modules/default-shell.nix
    ./../../modules/chromium.nix
    ./../../modules/flatpak-overrides.nix
    ./../../modules/tmux.nix
    ./../../modules/dev-packages.nix
    ./../../modules/dektop-packages.nix
    # ./../../modules/hyprland.nix
  ];

  # nixpkgs = {
  #   # You can add overlays here
  #   # Configure your nixpkgs instance
  #   config = {
  #     # Disable if you don't want unfree packages
  #     allowUnfree = true;
  #     # Workaround for https://github.com/nix-community/home-manager/issues/2942
  #     allowUnfreePredicate = _: true;
  #
  #     permittedInsecurePackages = ["openssl-1.1.1v" "electron-25.9.0"];
  #   };
  #   overlays = [];
  # };

  home.username = "mykolas";
  home.homeDirectory = "/home/mykolas";

  home.stateVersion = "23.11";

  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "tty";
  };

  programs = {
    # enable home-manager
    home-manager.enable = true;
    zsh = {
      initExtra = ''
        ${shell_hm_target}
      '';
    };
    bash = {
      bashrcExtra = ''
        ${shell_hm_target}
      '';
    };
  };

  xdg = {
    enable = true;
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
    "./.config/kitty" = {
      source = ./kitty;
      recursive = true;
      enable = true;
    };
    "./.config/waybar" = {
      source = ./waybar;
      recursive = true;
      enable = true;
    };
    "./.config/libvirt" = {
      source = ./libvirt;
      recursive = true;
      enable = true;
    };
    "./.gnupg/" = {
      source = ./gnupg;
      recursive = true;
      enable = true;
    };
    "./.gitconfig" = {
      source = ./gitconfig/gitconfig;
      enable = true;
    };
    "./.config/rofi" = {
      source = ./rofi/config;
      recursive = true;
      enable = true;
    };
    "./.local/share/rofi/themes" = {
      source = ./rofi/themes;
      recursive = true;
      enable = true;
    };
  };

  home.packages = with pkgs; [
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
    NIXOS_CONF_DIR = "$HOME/.nixconf";
  };

  # gtk = {
  #   enable = true;
  #   theme = {
  #     name = "WhiteSur";
  # package = pkgs.catppuccin-gtk.override {
  #   accents = ["pink"];
  #   size = "compact";
  #   tweaks = ["rimless" "black"];
  #   variant = "macchiato";
  # };
  # };

  # iconTheme = {
  #   package = pkgs.catppuccin-papirus-folders;
  #   name = "catppuccin-pairus-folders";
  # };
  #
  # font = {
  #   name = "Serif";
  #   size = 10;
  # };
  # };
}
