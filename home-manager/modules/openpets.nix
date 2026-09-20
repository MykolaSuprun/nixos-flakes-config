{
  pkgs,
  lib,
  config,
  ...
}: {
  options.myconf.openpets.enable = lib.mkEnableOption "OpenPets desktop companion";
  config = lib.mkIf config.myconf.openpets.enable {
    home.packages = with pkgs; [openpets];
  };
}
