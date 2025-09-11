{
  config,
  pkgs,
  ...
}: {
  imports = [];

  home.username = "mykolas";
  home.homeDirectory = "/home/mykolas";

  home.stateVersion = "24.11";

  xdg = {enable = true;};

  services.gpg-agent = {
    enable = true;
    # pinentryPackage = pkgs.pinentry-tty;
    pinentryPackage = pkgs.pinentry-bemenu;
  };

  programs = {
    # enable home-manager
    home-manager.enable = true;
  };
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # create home configuration files
  home.file = {
    "./.config/autostart" = {
      source = ./autostart;
      recursive = true;
    };
    "./.wezterm.lua".source = ./wezterm/wezterm.lua;
    "./.gitconfig".source = ./gitconfig/gitconfig;
    # "./.config/kitty" = {
    #   source = ./kitty;
    #   recursive = true;
    # };
    # "./.config/ghostty" = {
    #   source = ./ghostty;
    #   recursive = true;
    # };
    "./.gnupg/" = {
      source = ./gnupg;
      recursive = true;
    };
    # ".config/zellij" = {
    #   source = ./zellij;
    #   recursive = true;
    # };
  };

  home.packages = with pkgs; [];
}
