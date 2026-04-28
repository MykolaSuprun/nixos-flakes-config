{inputs, ...}: let
  helixConfig = import ../../lib/helix-config.nix;
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    packages.helix =
      (inputs.wrappers.wrapperModules.helix.apply {
        inherit pkgs;
        "config.toml".content = helixConfig.mkConfigToml {
          theme = helixConfig.themes.latte;
        };
      })
    .wrapper;
  };
}
