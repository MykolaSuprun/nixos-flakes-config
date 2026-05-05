{inputs, ...}: let
  weztermSharedConfig = import ../../lib/wezterm-config.nix;
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    weztermConfig = pkgs.writeText "wezterm.lua" (weztermSharedConfig.mkWeztermConfig {
      colorScheme = "Catppuccin Latte";
    });
    configDir = pkgs.linkFarm "wezterm-config" [
      {
        name = "wezterm.lua";
        path = weztermConfig;
      }
    ];
  in {
    packages.wezterm = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.wezterm;
      env = {
        WEZTERM_CONFIG_DIR = toString configDir;
      };
    };
  };
}
