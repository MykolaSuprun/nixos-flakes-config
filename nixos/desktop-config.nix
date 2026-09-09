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
          env = {
            DXVK_HDR = "1";
            ENABLE_GAMESCOPE_WSI = "1";
          };
          args = [
            "--adaptive-sync"
            "--hdr-enabled"
            "--hdr-itm-enable"
            "--mangoapp"
            "--rt"
            "--steam"
            "--xwayland-count 2"
            "--force-grab-cursor"
            "--expose-wayland"
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
                --hdr-enabled \
                --hdr-itm-enable \
                --mangoapp \
                -W 3440 -H 1440 -r 165 \
                -- ${pkgs.steam}/bin/steam -gamepadui -steamos
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
