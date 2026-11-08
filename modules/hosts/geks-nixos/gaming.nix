# Steam Big Picture session pinned to this host's hardware: RX 7900 XTX
# (Vulkan device 1002:744c) driving a 3440x1440@165 HDR VRR monitor.
_: {
  configurations.nixos.geks-nixos.module = {
    pkgs,
    lib,
    ...
  }: {
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
    };
  };
}
