{
  pkgs,
  config,
  lib,
  ...
}: {
  options.myconf.nixos.moshi-hook.enable =
    lib.mkEnableOption "Moshi host gateway (moshi-hook) for agent hook pairing";

  config = lib.mkIf config.myconf.nixos.moshi-hook.enable {
    environment.systemPackages = with pkgs; [
      moshi-hook
    ];

    # User-level daemon, bound to the Hyprland session exactly like the other
    # services in home-manager/modules/hyprland/settings.nix (swaync, awww,
    # hyprpolkitagent): BindsTo + WantedBy wayland-session@hyprland.desktop.target
    # with ConditionEnvironment so it never starts outside Hyprland.
    # Runs as the user (not root) so it can read ~/.config/moshi/ pairing
    # secrets and the agent hook sockets. Pair once manually:
    #   moshi-hook pair --token <token from Moshi>
    # Token stays in ~/.config/moshi/ — never in the nix store.
    home-manager.users.mykolas.systemd.user.services.moshi-hook = {
      Unit = {
        Description = "Moshi host gateway (moshi-hook serve)";
        ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
        BindsTo = ["wayland-session@hyprland.desktop.target"];
        After = ["wayland-session@hyprland.desktop.target"];
      };
      Service = {
        ExecStart = "${pkgs.moshi-hook}/bin/moshi-hook serve";
        Restart = "on-failure";
      };
      Install = {
        WantedBy = ["wayland-session@hyprland.desktop.target"];
      };
    };
  };
}