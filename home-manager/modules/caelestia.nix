{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  options.myconf.caelestia.enable = lib.mkEnableOption "Caelestia shell (quickshell-based desktop shell)";

  config = lib.mkIf config.myconf.caelestia.enable {
    programs.caelestia = {
      enable = true;

      systemd = {
        enable = true; # module-native autostart (same style as dms.nix)
        # UWSM session target (mirrors the noctalia unit in
        # hyprland/settings.nix) — NOT the HM default graphical-session.target.
        target = "wayland-session@hyprland.desktop.target";
      };

      cli.enable = true; # `caelestia` CLI: IPC (`caelestia shell …`), wallpaper/scheme switching

      # Sparse overrides only — upstream README warns a full dump of the
      # example config goes stale across updates. Everything omitted falls
      # back to upstream defaults (tunable at runtime via Nexus settings;
      # persistent changes belong here, HM rewrites shell.json on switch).
      settings = {
        general = {
          apps.terminal = ["ghostty"];
          # The shell's own idle daemon would fight hypridle (duplicate
          # suspend timers: shell suspends at 600s idle, hypridle at 1800s).
          # hypridle owns idle on this system → disarm the shell's.
          # (lockBeforeSleep stays true: belt-and-braces with before_sleep_cmd.)
          idle.timeouts = [];
        };
        paths.wallpaperDir = "${config.home.homeDirectory}/.config/wallpapers/catppuccin/${config.catppuccin.flavor}";
      };
    };

    # Only start inside a Hyprland session (mirrors the noctalia unit guard).
    systemd.user.services.caelestia.Unit.ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
  };
}
