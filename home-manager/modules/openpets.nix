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
        # Opt in to upstream's experimental native Wayland (wlr-layer-shell)
        # backend: the pet is a transparent overlay surface, not a framed
        # XWayland window. Requires resources/openpets-wayland-helper (built
        # by overlays/openpets.nix); falls back to the normal window path if
        # the helper cannot start.
        Environment = ["OPENPETS_NATIVE_WAYLAND=1"];
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
