final: prev: {
  # OpenPets desktop (Electron) repackaged from the official AppImage.
  # No nixpkgs package, NUR package, or third-party flake exists (verified 2026-09-10).
  # Asset naming: OpenPets-<version>-linux-x86_64.AppImage; hash via `nix store prefetch-file`.
  # AppImage contents verified: openpets.desktop + openpets.png at root,
  # usr/share/icons/hicolor/512x512/apps/openpets.png.
  openpets = prev.appimageTools.wrapType2 (finalAttrs: {
    pname = "openpets";
    version = "3.5.0";

    src = prev.fetchurl {
      url = "https://github.com/OpenPetsHQ/openpets/releases/download/v${finalAttrs.version}/OpenPets-${finalAttrs.version}-linux-x86_64.AppImage";
      hash = "sha256-d2gmcdBcL3+Gz2v0eeuEy3WTX/mw/Yf8T0go/eGsVVE=";
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
}
