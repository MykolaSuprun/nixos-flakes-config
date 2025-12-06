{
  pkgs,
  pkgs-stable,
  ...
}: {
  services.hardware = {
    bolt.enable = true;
  };
  hardware.steam-hardware.enable = true;
  services.teamviewer.enable = true;
  programs = {
    steam = {
      enable = true;
      protontricks.enable = true;
      extraCompatPackages = with pkgs; [proton-ge-bin];
      extraPackages = with pkgs; [mangohud gamescope];
      extest.enable = true;
      dedicatedServer.openFirewall = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;

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

  services = {
    displayManager.sessionPackages = [
      (pkgs.writeTextFile {
        name = "gamescope-steam-session";
        destination = "/share/wayland-sessions/gamescope-steam.desktop";
        text = ''
          [Desktop Entry]
          Name=Steam (Gamescope)
          Comment=Steam Big Picture Mode via Gamescope
          Exec=${pkgs.writeShellScript "gamescope-steam-optimized" ''
            ${pkgs.gamescope}/bin/gamescope \
              --rt \
              --prefer-vk-device 1002:744c \
              --expose-wayland \
              --force-grab-cursor \
              --adaptive-sync \
              -W 3840 -H 2160 -r 165 \
              -- ${pkgs.steam}/bin/steam -gamepadui -steamos
          ''}
          Type=Application
        '';
        passthru.providedSessions = ["gamescope-steam"];
      })
    ];

    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
      extraRules = [
        {
          "name" = "gamescope";
          "nice" = -20;
        }
      ];
    };
  };
  environment.systemPackages = with pkgs; [
    lutris
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
    winboat
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
