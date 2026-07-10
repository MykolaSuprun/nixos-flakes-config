{ lib, config, ... }: let
  opencodeSrcPath = "${config.home.sessionVariables.NIXOS_CONF_DIR}/home-manager/users/mykolas/config/opencode";
in {
  options.myconf.opencode.enable = lib.mkEnableOption "opencode AI editor config (live-editable symlink)";

  config = lib.mkIf config.myconf.opencode.enable {
    home.activation.linkOpencode = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p ~/.config/opencode
      rm -f ${config.home.homeDirectory}/.config/opencode/opencode.jsonc
      ln -s ${opencodeSrcPath}/opencode.jsonc ${config.home.homeDirectory}/.config/opencode/opencode.jsonc
    '';
  };
}
