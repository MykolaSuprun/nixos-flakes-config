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
    # alsa-utils (aplay/speaker-test) and pulseaudio client tools (pactl/paplay)
    # for CLI audio control — the pulseaudio daemon itself is NOT enabled.
    environment.systemPackages = [ pkgs.pipewire pkgs.alsa-utils pkgs.pulseaudio ];
    services = {
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber = {
          enable = true;
          # Disable automatic switching to HFP/HSP (handsfree) on any mic
          # request. With the default (true), any app grabbing a mic pulls a
          # BT headset into low-quality handsfree mode; Bose headsets then get
          # stuck there (codec-switch bug). Switching stays manual-only via
          # bt-profile-switch. (Previously an ad-hoc drop-in in
          # ~/.config/wireplumber/wireplumber.conf.d/ — now declarative.)
          extraConfig."11-bluetooth-policy" = {
            "wireplumber.settings" = {
              "bluetooth.autoswitch-to-headset-profile" = false;
            };
          };
        };
        socketActivation = true;
      };
      # Note: the pulseaudio daemon stays disabled; client tools come from
      # environment.systemPackages above (pactl talks to pipewire-pulse).
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
