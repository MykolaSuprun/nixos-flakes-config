{
  config,
  pkgs,
  ...
}: {
  imports = [];

  home.username = "mykolas";
  home.homeDirectory = "/home/mykolas";

  home.stateVersion = "23.11";

  xdg = {enable = true;};

  services.gpg-agent = {
    enable = true;
    grabKeyboardAndMouse = true;
    pinentry = {
      package = pkgs.pinentry-tty;
    };
  };

  programs = {
    home-manager.enable = true;
  };

  home.file = {
    "./.gitconfig".source = ./gitconfig/gitconfig;
    "./.gnupg/" = {
      source = ./gnupg;
      recursive = true;
    };
  };

  home.packages = with pkgs; [];
}
