{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./xdg.nix
    ./nix-conf.nix
    ./fonts.nix
    ./pipewire.nix
    ./input_method.nix
    ./sys-pkgs.nix
    ./desktop-config.nix
    ./catppuccin.nix
    ./hyprland.nix
    ./flatpak.nix
  ];

  catppuccin = {
    flavor = "latte";
    accent = "mauve";
  };

  programs = {
    ssh = {
      startAgent = true;
      enableAskPassword = true;
    };
    partition-manager.enable = true;
  };

  environment.sessionVariables = {
    SSH_ASKPASS_REQUIRE = "prefer";
    SYS_THEME =
      if config.catppuccin.enable
      then "catppuccin-${config.catppuccin.flavor}"
      else "";
  };
}
