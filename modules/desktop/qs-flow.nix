{inputs, ...}: {
  flake.modules.homeManager.qs-flow = {
    pkgs,
    lib,
    config,
    ...
  }: {
    imports = [inputs.qs-flow.homeManagerModules.default];
    # qs-flow — quickshell desktop shell (vendored minflair) with a three-layer
    # settings model (immutable HM base → dynamic user layer). Private flake:
    # git@gitlab.com:nix-private/qs-flow.git
    #
    # All behaviour is behind
    # `myconf.qs-flow.enable`, and the shipped HM module does the install +
    # autostart; this file only supplies nixconf-specific settings.
    options.myconf.qs-flow.enable = lib.mkEnableOption "qs-flow quickshell desktop shell";

    config = lib.mkIf config.myconf.qs-flow.enable {
      programs.qs-flow = {
        enable = true;

        # Select the consumer’s locked package explicitly; the flake export also supplies a default.
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

      # Applications launched by qs-flow may remain in its service cgroup.
      # Preserve them when the shell itself is restarted.
      systemd.user.services.qs-flow.Service.KillMode = "process";

      # Keep the module’s Wayland readiness guard alongside the host session guard.
      systemd.user.services.qs-flow.Unit.ConditionEnvironment = lib.mkForce [
        "WAYLAND_DISPLAY"
        "XDG_CURRENT_DESKTOP=Hyprland"
      ];
    };
  };
}
