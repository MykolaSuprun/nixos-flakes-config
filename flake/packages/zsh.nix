{inputs, ...}: let
  zshConfig = import ../../lib/zsh-config.nix;
in {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    packages.zsh =
      (inputs.wrappers.wrapperModules.zsh.apply {
        inherit pkgs;
        inherit (zshConfig) settings extraRC;
        extraPackages = zshConfig.extraPackages pkgs;
      })
    .wrapper;
  };
}
