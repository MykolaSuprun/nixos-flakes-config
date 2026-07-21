{
  config,
  pkgs,
  lib,
  ...
}: {
  options.myconf.nixos.secrets.enable = lib.mkEnableOption "Secret Service (KWallet/kwalletd6) for non-Plasma sessions";

  config = lib.mkIf config.myconf.nixos.secrets.enable {
    # KWallet (kwalletd6) provides the D-Bus SecretService API that apps like
    # ProtonVPN's GTK client rely on to store/retrieve credentials. Under
    # Plasma, Plasma's own starter activates kwalletd6; under Hyprland, the
    # `kwallet-pam-init` systemd oneshot in home-manager/modules/hyprland/
    # settings.nix drives activation + PAM unlock.
    #
    # Listed explicitly (rather than relying on plasma6 transitive pull) so the
    # secret service keeps working if Plasma is ever disabled on a host.
    environment.systemPackages = [
      pkgs.kdePackages.kwallet
      pkgs.kdePackages.kwallet-pam
    ];
  };
}