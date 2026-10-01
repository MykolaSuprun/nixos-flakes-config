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

    # Restart the pet after system resume: the unit above is oneshot +
    # RemainAfterExit with no Restart=, so a resume-killed process tree
    # leaves the unit "active" while the app is dead — nothing else will
    # ever restart it. User units WantedBy+After suspend.target run after
    # the system resumes (same pattern as audio-recovery.nix). Requisite
    # skips the restart cleanly when no graphical session is active
    # (suspend from a TTY or before login).
    systemd.user.services."openpets-resume-recovery" = {
      Unit = {
        Description = "Restart OpenPets after system resume";
        After = ["graphical-session.target" "suspend.target"];
        Requisite = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl --user restart openpets.service";
      };
      Install.WantedBy = ["suspend.target"];
    };
  };
}
