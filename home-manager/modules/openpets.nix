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

        # OpenPets' packaged bootstrap spawns the real process detached and
        # exits 0 after a ~600ms handoff. Under Type=simple, systemd treated
        # the unit as finished and killed the whole cgroup — including the
        # detached app ("start" looked like a no-op; unit: inactive/dead,
        # status=0/SUCCESS). oneshot + RemainAfterExit keeps the unit active
        # while the detached process tree lives on, and `stop` tears the
        # cgroup down cleanly (app + wayland helper). TimeoutStartSec bounds
        # the handoff. No Restart=: the app holds a single-instance lock, so
        # automatic retries can only relay into the running instance.
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "30s";
        # NOTE: OPENPETS_NATIVE_WAYLAND=1 is set (as a default) by the
        # package wrapper itself — every launch path (unit, uwsm/rofi
        # .desktop, tray) engages the layer-shell backend; see
        # overlays/openpets.nix.
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
