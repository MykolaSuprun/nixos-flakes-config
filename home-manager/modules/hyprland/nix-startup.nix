{
  inputs,
  pkgs,
  ...
}: let
in {
  wayland.windowManager.hyprland.settings.exec-once = [
    # "${inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/noctalia-shell"
  ];
}
