{pkgs, ...}: {
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

  programs = {
    ssh = {
      startAgent = true;
      enableAskPassword = true;
    };
  };

  environment.sessionVariables = {
    SSH_ASKPASS_REQUIRE = "prefer";
    SYS_THEME = "catppuccin-mocha";
  };
}
