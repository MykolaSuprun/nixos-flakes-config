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

  home.stateVersion = "23.11";

  xdg = {
    enable = true;
  };

  catppuccin.flavour = "latte";

  services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-tty;
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
  };

  home.packages = with pkgs; [
  ];

  home.sessionVariables = {
    NIXOS_CONF_DIR = "$HOME/.nixconf";
  };
}
