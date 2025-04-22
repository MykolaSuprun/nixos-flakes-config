{pkgs, ...}: {
  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services = {
    pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
    };
    pulseaudio.package = pkgs.pulseaudioFull;
  };
  # services = {
  #   jack.alsa.enable = true;
  #   jack.alsa.support32Bit = true;
  #
  #   pipewire = {
  #     enable = true;
  #     audio.enable = true;
  #     alsa.enable = true;
  #     alsa.support32Bit = true;
  #     pulse.enable = true;
  #     media-session.config.bluez-monitor.rules = [
  #       {
  #         # Matches all cards
  #         matches = [{"device.name" = "~bluez_card.*";}];
  #         actions = {
  #           "update-props" = {
  #             "bluez5.reconnect-profiles" = ["hfp_hf" "hsp_hs" "a2dp_sink"];
  #             # mSBC is not expected to work on all headset + adapter combinations.
  #             "bluez5.msbc-support" = true;
  #             # SBC-XQ is not expected to work on all headset + adapter combinations.
  #             "bluez5.sbc-xq-support" = true;
  #           };
  #         };
  #       }
  #       {
  #         matches = [
  #           # Matches all sources
  #           {"node.name" = "~bluez_input.*";}
  #           # Matches all outputs
  #           {"node.name" = "~bluez_output.*";}
  #         ];
  #         actions = {
  #           "node.pause-on-idle" = false;
  #         };
  #       }
  #     ];
  #     wireplumber = {
  #       enable = true;
  #       extraConfig.bluetoothEnhancements = {
  #         "monitor.bluez.properties" = {
  #           "bluez5.enable-sbc-xq" = true;
  #           "bluez5.enable-msbc" = true;
  #           "bluez5.enable-hw-volume" = true;
  #           "bluez5.roles" = ["hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag"];
  #         };
  #       };
  #     };
  #   };
  # };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
