{
  lib,
  config,
  ...
}: let
  kittyConfig = import ../../lib/kitty-config.nix;
in {
  options.myconf.kitty.enable = lib.mkEnableOption "kitty terminal emulator";
  config = lib.mkIf config.myconf.kitty.enable {
    programs.kitty = {
      enable = true;
      settings = kittyConfig.settings;
    };
  };
}

