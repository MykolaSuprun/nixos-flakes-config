final: prev: let
  # Full upstream source tree — needed to build the wlr-layer-shell helper
  # (openpets-wayland-helper below; upstream PR #166). Track the AppImage
  # version line on bumps: v4.0.1 == 10a2ccfc.
  openpetsSrc = prev.fetchFromGitHub {
    owner = "OpenPetsHQ";
    repo = "openpets";
    rev = "v4.0.1";
    hash = "sha256-eleCffuott6Z7VPZnv+CgQkwBzsgPsjO6j2BCOKreCo=";
  };
in {
  # OpenPets desktop (Electron) repackaged from the official AppImage.
  # No nixpkgs package, NUR package, or third-party flake exists (verified 2026-09-10; still none at 4.0.x).
  # Asset naming: OpenPets-<version>-linux-x86_64.AppImage; hash via `nix store prefetch-file`,
  # cross-checked against upstream SHA256SUMS (both agree for 4.0.1).
  # AppImage contents verified: openpets.desktop + openpets.png at root,
  # usr/share/icons/hicolor/512x512/apps/openpets.png.
  # NOTE: wrapAppImage, not wrapType2 — on this nixpkgs rev wrapType2's
  # extendDrvArgs ALWAYS recomputes `contents = extract {pname,version,src}`,
  # discarding a user-supplied contents. wrapAppImage (the layer below)
  # honours it (contents ? prev.src; runScript uses finalAttrs.contents).
  openpets = prev.appimageTools.wrapAppImage (finalAttrs: {
    pname = "openpets";
    version = "4.0.1";

    src = prev.fetchurl {
      url = "https://github.com/OpenPetsHQ/openpets/releases/download/v${finalAttrs.version}/OpenPets-${finalAttrs.version}-linux-x86_64.AppImage";
      hash = "sha256-qtsPP8RGpBMXSjn19Co0+czfm8C6VBa+hdXYtatFgjw=";
    };

    # Inject the layer-shell helper into the extraction itself, at exactly
    # the packaged location upstream intends (PR #166 "packaging" still
    # open): resources/openpets-wayland-helper, which Electron resolves via
    # process.resourcesPath relative to the real binary — a merged symlink
    # farm does NOT work (the farm links point back at the untouched
    # extraction, so resourcesPath never sees the helper).
    contents = prev.appimageTools.extract {
      inherit (finalAttrs) pname version src;
      postExtract = ''
        install -Dm755 ${final.openpets-wayland-helper}/bin/openpets-wayland-helper $out/resources/openpets-wayland-helper
      '';
    };

    extraInstallCommands = ''
      # wrapType2 names the wrapper $out/bin/<pname> or $out/bin/<pname>-<version>
      # depending on nixpkgs revision — normalize to $out/bin/openpets either way.
      for b in $out/bin/*; do
        [ "$(basename "$b")" != openpets ] && mv "$b" $out/bin/openpets
      done
      install -m 444 -D ${finalAttrs.contents}/openpets.desktop $out/share/applications/openpets.desktop
      install -m 444 -D ${finalAttrs.contents}/usr/share/icons/hicolor/512x512/apps/openpets.png $out/share/icons/hicolor/512x512/apps/openpets.png
      substituteInPlace $out/share/applications/openpets.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=openpets'

      # Wayland (Hyprland): activates when NIXOS_OZONE_WL=1 (already set on our Hyprland hosts).
      # No --no-sandbox: NixOS enables user namespaces; add only if sandbox errors force it.
      . ${prev.makeWrapper}/nix-support/setup-hook
      wrapProgram $out/bin/openpets \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
        --set-default OPENPETS_NATIVE_WAYLAND 1
      # ^ --set-default (not --set): the layer-shell backend must engage on
      # every launch path — systemd unit, uwsm/rofi .desktop launcher
      # (app-*.scope), tray, direct CLI — because the app's single-instance
      # lock makes whichever path starts FIRST win. Unit-only env proved
      # fragile: a launcher-started instance blocked the unit's (env-carrying)
      # relaunch. Escape hatch: OPENPETS_NATIVE_WAYLAND=0 overrides (falls
      # back to the x11-default backend, i.e. pre-fix behavior).
    '';

    meta = with prev.lib; {
      description = "Local-first desktop companion with animated pets, plugins, and coding-agent integrations";
      homepage = "https://github.com/OpenPetsHQ/openpets";
      license = licenses.mit; # upstream README: "The code is MIT, and stays MIT"
      mainProgram = "openpets";
      platforms = ["x86_64-linux"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
    };
  });

  # MCP stdio bridge for coding agents (opencode MCP config points at this).
  # Upstream ships the server as the npm package @open-pets/mcp and publishes
  # no lockfile, so a fully vendored nix build isn't practical: wrap node from
  # nixpkgs (>= 20 required) and let npm fetch/cache the pinned package on
  # first run — the same mechanism upstream's own install docs use.
  # Pin tracked manually against the desktop version line.
  openpets-mcp = prev.writeShellApplication {
    name = "openpets-mcp";
    runtimeInputs = [prev.nodejs];
    text = ''
      exec npx --yes @open-pets/mcp@4.0.0 "$@"
    '';
    meta = with prev.lib; {
      description = "OpenPets MCP stdio server (Node wrapper around @open-pets/mcp)";
      homepage = "https://github.com/OpenPetsHQ/openpets";
      license = licenses.mit;
      mainProgram = "openpets-mcp";
      platforms = ["x86_64-linux"];
    };
  };

  # Native Rust helper that owns the wlr-layer-shell overlay surface: the
  # hidden Electron renderer streams BGRA pet frames to it over a unix
  # socket (~30fps). Activated via OPENPETS_NATIVE_WAYLAND=1 (set in the
  # systemd user unit). Without it, pet windows degrade to framed opaque
  # XWayland windows on Hyprland/Niri (the Electron X11 shell-exclusion
  # dance times out — the reason for the visible frame we hit in v4.0.1).
  openpets-wayland-helper = prev.rustPlatform.buildRustPackage {
    pname = "openpets-wayland-helper";
    version = "4.0.1";

    src = openpetsSrc;
    # Crate root is self-contained (own Cargo.toml + Cargo.lock).
    sourceRoot = "source/apps/desktop/native/openpets-wayland-helper";

    cargoLock = {
      lockFile = "${openpetsSrc}/apps/desktop/native/openpets-wayland-helper/Cargo.lock";
    };

    # smithay-client-toolkit's build.rs drives pkg-config to find xkbcommon.
    nativeBuildInputs = [prev.pkg-config];
    buildInputs = [prev.wayland prev.libxkbcommon];

    meta = with prev.lib; {
      description = "Rust helper carrying the OpenPets pet on a wlr-layer-shell overlay surface (native Wayland backend, upstream PR #166)";
      homepage = "https://github.com/OpenPetsHQ/openpets/tree/main/apps/desktop/native/openpets-wayland-helper";
      license = licenses.mit;
      mainProgram = "openpets-wayland-helper";
      platforms = ["x86_64-linux"];
    };
  };
}
