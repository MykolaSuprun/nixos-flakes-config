{inputs, ...}: let
  kittyConfig = import ../../lib/kitty-config.nix;
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    packages.kitty = (inputs.wrappers.wrapperModules.kitty.apply {
      inherit pkgs;
      settings = kittyConfig.settings // kittyConfig.themes.latte;
    })
    .wrapper;
  };
}
