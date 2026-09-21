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

    # User-level unit, MANUAL start only (2026-09-20: on-demand by user decision —
    # no autostart of a proprietary always-on agent bridge). Start it with:
    #   systemctl --user start moshi-hook
    # ConditionEnvironment keeps it from starting outside a Hyprland session.
    # Runs as the user (not root) so it can read ~/.config/moshi/ pairing
    # secrets and the agent hook sockets. Pair once manually:
    #   moshi-hook pair --token <token from Moshi>
    # Token stays in ~/.config/moshi/ — never in the nix store.
    home-manager.users.mykolas.systemd.user.services.moshi-hook = {
      Unit = {
        Description = "Moshi host gateway (moshi-hook serve)";
        ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
      };
      Service = {
        ExecStart = "${pkgs.moshi-hook}/bin/moshi-hook serve";
        Restart = "on-failure";
      };
      # No Install.WantedBy: intentionally not pulled in by any target.
    };
  };
}
