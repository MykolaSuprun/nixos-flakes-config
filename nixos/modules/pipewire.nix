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
}
