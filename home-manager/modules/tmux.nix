{
  pkgs,
  lib,
  config,
  ...
}: let
  tmuxConfig = import ../../lib/tmux-config.nix;
  tmuxConfText = tmuxConfig.mkTmuxConf {
    inherit pkgs;
    catppuccinFlavor = config.catppuccin.flavor;
    tmuxpPresetsDir = ../users/mykolas/config/tmuxp;
    seshConfigFile = ../users/mykolas/config/sesh/sesh.toml;
  };
in {
  options.myconf.tmux.enable = lib.mkEnableOption "tmux terminal multiplexer";
  config = lib.mkIf config.myconf.tmux.enable {
    programs.tmux = {
      enable = true;
      extraConfig = tmuxConfText;
    };
    home.packages = tmuxConfig.runtimeInputs pkgs;
  };
}

