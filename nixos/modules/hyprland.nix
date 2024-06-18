{
  inputs,
  pkgs,
  ...
}: {
  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      systemd.setPath.enable = true;
      xwayland.enable = true;
    };
    hyprlock.enable = true;
  };
  services.blueman.enable = true;
  # services.hypridle.enable = true;
}
