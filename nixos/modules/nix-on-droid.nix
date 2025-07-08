{pkgs, ...}: {
  imports = [
    # ./nix-conf.nix
    # ./fonts.nix
    # ./sys-pkgs.nix
    # ./catppuccin.nix
  ];

  environment.sessionVariables = {
    # SYS_THEME = "catppuccin-latte";
  };
}
