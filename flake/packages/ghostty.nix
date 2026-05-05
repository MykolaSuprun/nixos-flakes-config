{inputs, ...}: let
  ghosttyConfig = import ../../lib/ghostty-config.nix;
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    packages.ghostty =
      (inputs.wrappers.wrapperModules.ghostty.apply {
        inherit pkgs;
        settings = ghosttyConfig.settings // ghosttyConfig.themes.latte;
      })
    .wrapper;
  };
}
