{
  pkgs,
  lib,
  config,
  ...
}: {
  options.myconf.helix.enable = lib.mkEnableOption "helix editor";
  config = lib.mkIf config.myconf.helix.enable {
    programs.helix = {
      enable = true;
      settings = {
        editor.line-number = "relative";
      };
    };
  };
}

