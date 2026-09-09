# Restart the user audio stack after system resume.
# On this platform every S3 resume re-initializes the xHCI USB controllers,
# which kills BT audio transports and can leave the PipeWire graph wedged
# (adapter nodes without ports, zero links — total silence until restarted).
# User units WantedBy+After suspend.target start after the system resumes.
{
  pkgs,
  config,
  lib,
  ...
}: {
  options.myconf.audio-recovery.enable = lib.mkEnableOption "restart PipeWire/WirePlumber after system resume";

  config = lib.mkIf config.myconf.audio-recovery.enable {
    systemd.user.services."audio-resume-recovery" = {
      Unit = {
        Description = "Restart PipeWire stack after resume (xHCI reinit wedges the audio graph)";
        After = ["suspend.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service";
      };
      Install = {
        WantedBy = ["suspend.target"];
      };
    };
  };
}
