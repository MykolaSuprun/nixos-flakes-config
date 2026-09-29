{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.myconf.openpets;
in {
  options.myconf.openpets.enable = lib.mkEnableOption "OpenPets desktop companion";

  config = lib.mkIf cfg.enable {
    # Desktop app (AppImage repack) + MCP stdio bridge for coding agents.
    home.packages = [pkgs.openpets pkgs.openpets-mcp];

    # Autostart with the desktop session: the app is tray-first and the
    # MCP bridge needs it running to drive pet reactions.
    systemd.user.services.openpets = {
      Unit = {
        Description = "OpenPets desktop companion";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.openpets}/bin/openpets";
        Restart = "on-failure";
        # NOTE: OPENPETS_NATIVE_WAYLAND=1 is set (as a default) by the
        # package wrapper itself — so every launch path (unit, uwsm/rofi
        # .desktop, tray) engages the layer-shell backend, not just this
        # unit. No unit-level Environment needed; see overlays/openpets.nix.
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
