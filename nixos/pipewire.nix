{
  pkgs,
  config,
  lib,
  ...
}: {
  options.myconf.nixos.pipewire.enable = lib.mkEnableOption "PipeWire audio + Bluetooth";

  config = lib.mkIf config.myconf.nixos.pipewire.enable {
    # Enable sound with pipewire.
    security.rtkit.enable = true;
    # Expose libpipewire-0.3.so.0 in /run/current-system/sw/lib so Qt Multimedia
    # can dlopen() it at runtime (resolves "Couldn't load pipewire-0.3 library" warning).
    environment.systemPackages = [ pkgs.pipewire ];
    services = {
      pipewire = {
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
        socketActivation = true;
      };
      pulseaudio.package = pkgs.pulseaudioFull;
    };

    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Enable = "Source,Sink,Media,Socket";
            Experimental = true;
          };
        };
      };
    };
  };
}
