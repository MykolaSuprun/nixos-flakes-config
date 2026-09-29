final: prev: {
  # OpenPets desktop (Electron) repackaged from the official AppImage.
  # No nixpkgs package, NUR package, or third-party flake exists (verified 2026-09-10; still none at 4.0.x).
  # Asset naming: OpenPets-<version>-linux-x86_64.AppImage; hash via `nix store prefetch-file`,
  # cross-checked against upstream SHA256SUMS (both agree for 4.0.1).
  # AppImage contents verified: openpets.desktop + openpets.png at root,
  # usr/share/icons/hicolor/512x512/apps/openpets.png.
  openpets = prev.appimageTools.wrapType2 (finalAttrs: {
    pname = "openpets";
    version = "4.0.1";

    src = prev.fetchurl {
      url = "https://github.com/OpenPetsHQ/openpets/releases/download/v${finalAttrs.version}/OpenPets-${finalAttrs.version}-linux-x86_64.AppImage";
      hash = "sha256-qtsPP8RGpBMXSjn19Co0+czfm8C6VBa+hdXYtatFgjw=";
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
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
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
}
