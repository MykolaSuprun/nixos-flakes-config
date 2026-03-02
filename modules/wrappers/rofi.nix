{inputs, ...}: let
  rofiConfig = import ../../lib/rofi-config.nix;
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    packages.rofi = (inputs.wrappers.wrapperModules.rofi.apply {
      inherit pkgs;
      "config.rasi".content = rofiConfig.mkConfigRasi {
        theme = "catppuccin-latte";
      };
    })
    .wrapper;
  };
}
