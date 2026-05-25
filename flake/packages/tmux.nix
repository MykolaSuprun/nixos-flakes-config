{inputs, ...}: let
  tmuxConfig = import ../../lib/tmux-config.nix;
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    tmuxConf = pkgs.writeText "tmux.conf" (tmuxConfig.mkTmuxConf {
      inherit pkgs;
      catppuccinFlavor = "latte";
      tmuxpPresetsDir = ../../home-manager/users/mykolas/config/tmuxp;
      seshConfigFile = ../../home-manager/users/mykolas/config/sesh/sesh.toml;
    });
  in {
    packages.tmux = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.tmux;
      flags = {
        "-f" = toString tmuxConf;
      };
      runtimeInputs = tmuxConfig.runtimeInputs pkgs;
    };
  };
}
