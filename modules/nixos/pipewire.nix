{ inputs, pkgs, config, ... }: {
#  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;
  hardware.pulseaudio.extraConfig = "unload-module module-role-cork";
  security.rtkit.enable = true;
  # hardware.pulseaudio.configFile = pkgs.runCommand "default.pa" {} ''
  #   grep -v module-role-cork ${config.hardware.pulseaudio.package}/etc/pulse/default.pa > $out
  # '';
  # nixpkgs.config.pulseaudio = true;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  #   wireplumber.enable = true;
  #   # If you want to use JACK applications, uncomment this
  #   jack.enable = true;
  # };
}