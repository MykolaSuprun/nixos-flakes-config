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
  };
}