{inputs, lib, config, ...}: let
  # Config lives in the private nixconf-private repo (the model list is
  # private). Prefer the local clone (live-editable); fall back to the flake
  # input's store path (read-only) when the clone isn't present on this host.
  privateClone = "${config.home.sessionVariables.NIXOS_CONF_DIR}/../nixconf-private/opencode/opencode.jsonc";
  storeFallback = "${inputs.nixconf-private}/opencode/opencode.jsonc";
in {
  options.myconf.opencode.enable = lib.mkEnableOption "opencode AI editor config (live-editable symlink)";

  config = lib.mkIf config.myconf.opencode.enable {
    home.activation.linkOpencode = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p ~/.config/opencode
      rm -f ${config.home.homeDirectory}/.config/opencode/opencode.jsonc
      if [[ -f ${privateClone} ]]; then
        ln -s ${privateClone} ${config.home.homeDirectory}/.config/opencode/opencode.jsonc
      else
        ln -s ${storeFallback} ${config.home.homeDirectory}/.config/opencode/opencode.jsonc
      fi
    '';
  };
}
