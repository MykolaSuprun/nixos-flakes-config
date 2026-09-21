{
  pkgs,
  pkgs-stable,
  lib,
  config,
  ...
}: {
  options.myconf.nixos.desktop.enable = lib.mkEnableOption "gaming and desktop apps";
  config = lib.mkIf config.myconf.nixos.desktop.enable {
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
        dedicatedServer.openFirewall = true;
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
      displayManager.sessionPackages = [
        (pkgs.writeTextFile {
          name = "gamescope-steam-session";
          destination = "/share/wayland-sessions/gamescope-steam.desktop";
          text = let
            # NOTE (2026-09-11): --mangoapp REMOVED — same XInternAtom crash-loop as steam-gamescope wrapper.
            gamescopeArgs = [
              "--rt"
              "--prefer-vk-device"
              "1002:744c"
              "--expose-wayland"
              "--force-grab-cursor"
              "--adaptive-sync"
              "--hdr-enabled"
              "--hdr-itm-enable"
              "-W"
              "3440"
              "-H"
              "1440"
              "-r"
              "165"
            ];
          in ''
            [Desktop Entry]
            Name=Steam (Gamescope)
            Comment=Steam Big Picture Mode via Gamescope
            Exec=${pkgs.writeShellScript "gamescope-steam-optimized" ''
              exec ${pkgs.gamescope}/bin/gamescope ${lib.escapeShellArgs gamescopeArgs} -- ${pkgs.steam}/bin/steam -gamepadui -steamos
            ''}
            Type=Application
          '';
          passthru.providedSessions = ["gamescope-steam"];
        })
      ];

      ananicy = {
        # Disabled: ananicy-cpp 1.2.0 fails to build on current nixpkgs
        # (glibc 2.42 header tightening, missing <cstring>/<cstdint> —
        # NixOS/nixpkgs#552211). Re-enable once the fix lands upstream.
        enable = false;
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
      pkgs-stable.lutris
      thunderbolt
      bolt
      tbtools
      kdePackages.plasma-thunderbolt
      pkgs-stable.bazecor
      steam-run
      # looking-glass-client
      spice
      steamtinkerlaunch
      pkgs-stable.winboat
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

    # Restart bluetoothd after resume: on this platform every S3 resume fails on
    # all xHCI controllers ("xHC error in resume, USBSTS 0x401, Reinit"), which
    # re-enumerates the BT adapter (hci0<->hci1) and leaves bluetoothd with stale
    # MediaEndpoints — BT audio then fails with "a2dp-sink profile connect
    # failed: Device or resource busy" until bluetoothd is restarted.
    # WantedBy+After suspend.target = starts after the system resumes.
    systemd.services."bluetooth-resume-recovery" = {
      description = "Restart bluetooth after resume (xHCI reinit wedges BT audio)";
      wantedBy = ["suspend.target"];
      after = ["suspend.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl restart bluetooth.service";
      };
    };
  };
}
