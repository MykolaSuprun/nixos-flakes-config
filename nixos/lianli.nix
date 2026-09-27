# Lian Li device control via lian-li-linux (open L-Connect 3 replacement).
# Installs the package, ships udev rules for non-root USB/hidraw access, and
# runs lianli-daemon per-user (GUI/cli talk to it over a $XDG_RUNTIME_DIR
# socket). Device scope on geks-nixos: HydroShift LCD 360R AIO (0416:7399) +
# UNI FAN SL V2 hub (0cf2:a105). The udev rules reference GROUP="lianli", so
# the group must exist. No evdi kernel module (no desktop-mode LCD devices).
{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.myconf.nixos.lianli;
in {
  options.myconf.nixos.lianli = {
    enable = lib.mkEnableOption "lian-li-linux — Lian Li AIO/fan control daemon + GUI (fan curves, pump, RGB, LCD streaming)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.lianli-linux;
      defaultText = lib.literalExpression "pkgs.lianli-linux";
      description = "The lianli-linux package to use (overlay: pkgs/lian-li-linux).";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    # Non-root USB/hidraw access for Lian Li devices (uaccess + lianli group).
    services.udev.packages = [cfg.package];
    users.groups.lianli = {};

    # v1.1.x daemon refuses to start without these root-owned shared flock
    # files (both user-mode and system-mode daemons share them).
    # Mirrors upstream packaging/tmpfiles.d/lianli.conf.
    systemd.tmpfiles.rules = [
      "f /run/lianli-daemon.lock 0666 root root - -"
      "f /run/lianli-control.lock 0666 root root - -"
    ];

    # Per-user daemon: talks to the GUI via a socket in $XDG_RUNTIME_DIR.
    systemd.user.services.lianli-daemon = {
      description = "Lian Li Device Daemon";
      wantedBy = ["default.target"];
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/lianli-daemon";
        Restart = "on-failure";
        RestartSec = 5;
        # Shell-command and NvidiaGpu fan-curve sensor sources run via
        # `Command::new("sh")` and call out to nvidia-smi / awk etc. The default
        # systemd user PATH is coreutils-only (no `sh`!), so point the daemon at
        # the system profile for those sensor sources to work.
        Environment = "PATH=/run/wrappers/bin:/run/current-system/sw/bin";
      };
    };
  };
}
