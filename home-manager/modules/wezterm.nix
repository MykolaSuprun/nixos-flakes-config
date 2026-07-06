{
  pkgs,
  lib,
  config,
  ...
}: let
  weztermConfig = import ../../lib/wezterm-config.nix;
  # Map catppuccin flavor to wezterm color scheme name
  colorScheme = {
    latte = "Catppuccin Latte";
    frappe = "Catppuccin Frappe";
    macchiato = "Catppuccin Macchiato";
    mocha = "Catppuccin Mocha";
  }.${config.catppuccin.flavor};
in {
  options.myconf.wezterm.enable = lib.mkEnableOption "wezterm terminal emulator";
  config = lib.mkIf config.myconf.wezterm.enable {
    programs.wezterm = {
      enable = true;
      extraConfig = weztermConfig.mkWeztermConfig {inherit colorScheme;};
    };
  };
}

