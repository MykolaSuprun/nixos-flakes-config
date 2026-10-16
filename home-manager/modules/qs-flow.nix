{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  # qs-flow — quickshell desktop shell (vendored minflair) with a three-layer
  # settings model (immutable HM base → dynamic user layer). Private flake:
  # git@gitlab.com:nix-private/qs-flow.git
  #
  # Mirrors dms.nix / caelestia.nix: all behaviour is behind
  # `myconf.qs-flow.enable`, and the shipped HM module does the install +
  # autostart; this file only supplies nixconf-specific settings.
  options.myconf.qs-flow.enable = lib.mkEnableOption "qs-flow quickshell desktop shell";

  config = lib.mkIf config.myconf.qs-flow.enable {
    programs.qs-flow = {
      enable = true;

      # The module cannot resolve the flake input itself — pass the package.
      package = inputs.qs-flow.packages.${pkgs.stdenv.hostPlatform.system}.qs-flow;

      autostart = {
        enable = true;
        target = "wayland-session@hyprland.desktop.target";
        restartIfChanged = true;
      };

      # Immutable BASE settings (nix store). The shell merges the dynamic layer
      # (~/.config/qs-flow/settings.json) ON TOP of these, so anything here is a
      # revertable default: delete that file to come back to this. Keep this
      # SPARSE — every key omitted inherits the shell's own defaults.
      settings = {
        barStyle = "convex";
        clock24h = false; # 12h clock, matches catppuccin/hyprland setup
        clockShowDate = true;
        # bar slots (convex style): see SettingsService.barSlot* in the shell
        barSlotL1 = "workspaces";
        barSlotC1 = "clock";
        barSlotC2 = "media";
        barSlotR1 = "recording";
        barSlotR2 = "control_center";
        barSlotR3 = "tray";
        # NixOS is not Arch: the vendored update module shells out to
        # `checkupdates`/`yay` which do not exist here, so keep the check off
        # rather than showing a permanently broken widget.
        packageManagerMode = "install";
      };
    };


    # REsume recovery: on this machine the amdgpu/DRI output-reset storm that
    # follows every S3 resume kills Wayland RENDERING while the quickshell
    # process survives (event loop answers IPC; surfaces stay mapped but the
    # frame is stale and no new windows can map). A live-but-wedged shell is
    # invisible to Restart=always — the process has to be recycled from the
    # outside. Same pattern as audio-recovery.nix: user units WantedBy+After
    # suspend.target start after the system resumes. Unconditional restart:
    # probing (IPC answers even when wedged) costs more than the ~2s bar
    # rebuild — and the screen is coming up from black anyway.
    systemd.user.services."qs-flow-resume-recovery" = {
      Unit = {
        Description = "Restart qs-flow after resume (DRI output-reset storm wedges rendering while the process survives)";
        After = ["suspend.target" "qs-flow.service"];
      };
      Service = {
        Type = "oneshot";
        # NEVER restart while the shell holds the ext-session-lock: killing
        # the lock client makes the compositor keep the screen locked and
        # painted solid (protocol: "the lock dying will not expose your
        # session, but it will render it inoperable") — the user would be
        # unable to unlock. Probe first; restart only when not locked.
        ExecStart = "${pkgs.writeShellScriptBin "qs-flow-resume-guard" ''
          if qs-flow-islocked 2>/dev/null; then
            echo "qs-flow-resume-guard: shell holds the session lock - skipping restart" >&2
            exit 0
          fi
          exec ${pkgs.systemd}/bin/systemctl --user restart qs-flow.service
        ''}/bin/qs-flow-resume-guard";
      };
      Install = {
        WantedBy = ["suspend.target"];
      };
    };

    # Only run inside a Hyprland session (same guard style as dms/noctalia).
    systemd.user.services.qs-flow.Unit.ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
  };
}
