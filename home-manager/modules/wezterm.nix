{
  lib,
  config,
  ...
}: let
  weztermConfig = import ../../lib/wezterm-config.nix;
in {
  options.myconf.wezterm.enable = lib.mkEnableOption "wezterm terminal emulator";
  config = lib.mkIf config.myconf.wezterm.enable {
    programs.wezterm = {
      enable = true;
      extraConfig = weztermConfig.mkWeztermConfig {};
    };
  };
}

