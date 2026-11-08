_: {
  flake.modules.nixos.desktop = {
    pkgs,
    lib,
    config,
    ...
  }: {
    options.myconf.nixos.desktop.enable = lib.mkEnableOption "gaming and desktop apps";
    config = lib.mkIf config.myconf.nixos.desktop.enable {
      qt.enable = true;
      services.hardware = {
        bolt.enable = true;
      };
      # Crash-loop defense (2026-09-11): bound systemd-coredump so a respawning
      # crasher (e.g. mangoapp, 96k dumps/day observed) can't saturate disk/IO.
      # Depth only — the real fix is removing the crasher (see --mangoapp notes).
      environment.etc."systemd/coredump.conf.d/10-limits.conf".text = ''
        [Coredump]
        MaxUse=2G
        KeepFree=30G
        ProcessSizeMax=1G
        ExternalSizeMax=1G
      '';
      hardware.steam-hardware.enable = true;
      programs = {
        steam = {
          enable = true;
          protontricks.enable = true;
          extraCompatPackages = with pkgs; [proton-ge-bin];
          extraPackages = with pkgs; [mangohud gamescope];
          extest.enable = true;
          # No dedicated servers run here — keep 27015 closed.
          dedicatedServer.openFirewall = false;
          remotePlay.openFirewall = true;
          localNetworkGameTransfers.openFirewall = true;

          gamescopeSession = {
            enable = true;
            env = {
              DXVK_HDR = "1";
              ENABLE_GAMESCOPE_WSI = "1";
            };
            args = [
              "--adaptive-sync"
              "--hdr-enabled"
              "--hdr-itm-enable"
              # NOTE (2026-09-11): "--mangoapp" REMOVED — same XInternAtom crash-loop as steam-gamescope wrapper.
              "--rt"
              "--steam"
              "--xwayland-count 2"
              "--force-grab-cursor"
              "--expose-wayland"
            ];
          };
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
      };

      services = {
        # These desktop services were previously enabled by the Plasma module.
        accounts-daemon.enable = true;
        libinput.enable = true;
        power-profiles-daemon.enable = lib.mkDefault true;
        udisks2.enable = true;
        upower.enable = true;
      };
      environment.systemPackages = with pkgs; [
        thunderbolt
        bolt
        tbtools
        pkgs.stable.bazecor
        steam-run
        # looking-glass-client
        spice
        steamtinkerlaunch
        pkgs.stable.winboat
      ];

      systemd.services.unblock-bluetooth = {
        description = "Unblock Bluetooth using rfkill";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
        };
        wantedBy = ["sysinit.target"]; # Run early in the boot process
      };
    };
  };
}
