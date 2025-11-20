{
  pkgs,
  pkgs-stable,
  ...
}: {
  services.hardware.bolt.enable = true;
  services.teamviewer.enable = true;
  programs = {
    steam = {
      enable = true;
      protontricks.enable = true;
      extraCompatPackages = with pkgs; [proton-ge-bin];
      extraPackages = with pkgs; [mangohud gamescope];
      extest.enable = true;
      gamescopeSession = {
        enable = true;
        env = {DXVK_HDR = "1";};
        args = [
          "--adaptive-sync"
          # "--hdr-enabled"
          "--mangoapp"
          # "--rt"
          "--steam"
          "--xwayland-count 2"
          # "-b"
          # "-f"
          # "-w 3440"
          # "-h 1440"
          "-r 165"
          # "--expose-wayland"
          # "--backend wayland"
        ];
      };
      # gamescopeSession.args = [
      #   "-f -b -g -e --rt -w 3440 -h 1440 -W 3440 -H 1440 -r 165"
      #   "--hdr-enabled --force-grab-cursor --immediate-flips --mangoapp"
      #   "--adaptive-sync --backend=wayland --expose-wayland"
      # ];
      # extraPackages = [ pkgs.gamescope ];
    };
    gamemode = {
      enable = true;
      enableRenice = true;
    };
    kdeconnect.enable = true;
    gamescope = {
      enable = true;
      capSysNice = false;
    };
    firefox = {
      enable = true;
      package = pkgs.firefox;
    };
  };

  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-cpp;
    extraRules = [
      {
        "name" = "gamescope";
        "nice" = -20;
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    ayugram-desktop
    thunderbolt
    bolt
    tbtools
    kdePackages.plasma-thunderbolt
    bazecor
    steam-run
    # looking-glass-client
    spice
    nexusmods-app-unfree
    steamtinkerlaunch
    # winboat
  ];

  systemd.services.unblock-bluetooth = {
    description = "Unblock Bluetooth using rfkill";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
      User = "root"; # Ensure it runs with necessary permissions
    };
    wantedBy = ["sysinit.target"]; # Run early in the boot process
  };
}
