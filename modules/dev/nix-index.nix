# nix-index with the weekly prebuilt database from nix-index-database:
# command-not-found suggestions and `,` (comma) work without ever running
# `nix-index` locally.
{inputs, ...}: {
  flake.modules.homeManager.nix-index = {
    config,
    lib,
    ...
  }: {
    imports = [inputs.nix-index-database.homeModules.nix-index];

    options.myconf.nix-index.enable = lib.mkEnableOption "nix-index + comma with a prebuilt database";

    config = lib.mkIf config.myconf.nix-index.enable {
      programs.nix-index = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
      };
      programs.nix-index-database.comma.enable = true;
    };
  };
}
