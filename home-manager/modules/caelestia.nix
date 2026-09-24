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

      cli = {
        enable = true; # `caelestia` CLI: IPC (`caelestia shell …`), wallpaper/scheme switching
        # Theme engine fully disarmed: every target defaults to ON when
        # cli.json has no theme section, and each scheme change would
        # otherwise recolor live terminals (OSC to all ptys), rewrite
        # fuzzel/htop/btop configs, flip dconf GTK/Qt behind Stylix's back,
        # and drop files into the Hyprland config. Persistent theming is
        # Nix-managed (Stylix + catppuccin-nix); light/dark switching across
        # all apps belongs in NixOS specialisations, not this runtime engine.
        # The shell itself still recolors from state/scheme.json (ungated).
        settings.theme = {
          enableTerm = false;
          enableHypr = false;
          enableDiscord = false;
          enableSpicetify = false;
          enablePandora = false;
          enableFuzzel = false;
          enableBtop = false;
          enableNvtop = false;
          enableHtop = false;
          enableGtk = false;
          enableQt = false;
          enableWarp = false;
          enableChromium = false;
          enableZed = false;
          enableCava = false;
        };
      };

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
        # No automatic light/dark flips by wallpaper luminance: with a static
        # scheme each flip is a flavour change the user must choose (mocha has
        # no light mode, latte no dark one). Long term the shell flavour
        # should track myconf.catppuccin.flavor via the flavour
        # specialisations (nixos/specialisations.nix).
        services.smartScheme = false;
      };
    };

    # Only start inside a Hyprland session (mirrors the noctalia unit guard).
    systemd.user.services.caelestia.Unit.ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
  };
}
