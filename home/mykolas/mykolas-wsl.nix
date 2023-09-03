{pkgs, ...}: let
  hm_target = "mykolas-wsl";
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

    ./../../modules/home-manager/default-shell.nix
    ./../../modules/home-manager/tmux.nix
    ./../../modules/home-manager/dev-packages.nix
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
    "./.config/tmux.conf" = {
      source = ./tmux/tmux.conf;
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
    chromium
    wsl-vpnkit
    wsl-open
    wslu
  ];

  home.sessionVariables = {
  };
}
