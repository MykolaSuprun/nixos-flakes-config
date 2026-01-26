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
    grabKeyboardAndMouse = true;
    pinentry = {
      package = pkgs.pinentry-tty;
    };
    # pinentryPackage = pkgs.pinentry-tty;
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
    "./.config/clipse" = {
      source = ./clipse;
      recursive = true;
    };
    "./.config/freerdp/sdl-freerdp.json".source = ./freerdp/sdl-freerdp.json;
    "./.wezterm.lua".source = ./wezterm/wezterm.lua;
    "./.gitconfig".source = ./gitconfig/gitconfig;
    "./.config/superfile" = {
      source = ./superfile;
      recursive = true;
    };

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
