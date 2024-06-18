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
  ];

  home.username = "mykolas";
  home.homeDirectory = "/home/mykolas";

  home.stateVersion = "24.05";

  xdg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    # pinentryPackage = pkgs.pinentry-tty;
    pinentryPackage = pkgs.pinentry-bemenu;
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
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # create home configuration files
  home.file = {
    "./.wezterm.lua".source = ./wezterm/wezterm.lua;
    "./.gitconfig".source = ./gitconfig/gitconfig;
    "./.config/hypr/hyprlock.conf".source = ./hyprlock/hyprlock.conf;
    "./.config/hypr/hypridle.conf".source = ./hypridle/hypridle.conf;
    "./.config/hypr/pyprland.toml".source = ./pyprland/pyprland.toml;
    "./.config/xdg-desktop-portal/hyprland-portals.conf".source = ./hyprland-portals/hyprland-portals.conf;
    "./.config/helix" = {
      source = ./helix;
      recursive = true;
    };
    "./.config/kitty" = {
      source = ./kitty;
      recursive = true;
    };
    "./.config/alacritty" = {
      source = ./alacritty;
      recursive = true;
    };
    "./.config/libvirt" = {
      source = ./libvirt;
      recursive = true;
    };
    "./.gnupg/" = {
      source = ./gnupg;
      recursive = true;
    };
    ".config/zellij" = {
      source = ./zellij;
      recursive = true;
    };
  };

  home.packages = with pkgs; [
    dconf
  ];

  home.sessionVariables = {
    NIXOS_CONF_DIR = "$HOME/.nixconf";
  };
}
