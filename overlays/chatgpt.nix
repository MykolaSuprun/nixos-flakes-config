final: prev:
# ChatGPT desktop for Linux (OpenAI official .deb repackaged).
# nixpkgs `chatgpt` is darwin-only (verified 2026-09-12:
# pkgs/by-name/ch/chatgpt/package.nix, platforms = darwin).
# Linux upstream ships a .deb, not an AppImage, so wrapType2 (cf. openpets.nix)
# does not apply — this follows the community dpkg + autoPatchelf pattern
# (hhyurdagul/chatgpt-nix, package.nix) collapsed into a single file because
# overlays/default.nix imports every file in this dir (companions .sh/.py
# would be mis-imported as overlays).
#
# Asset naming: chatgpt_<version>_<amd64|arm64>.deb at
# https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/
# Update: check both arch stanzas, they must agree on one version:
#   curl -fsSL https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-{amd64,arm64}/Packages \
#     | grep -E '^(Version|Filename|SHA256):'
#   nix --extra-experimental-features nix-command hash convert --hash-algo sha256 --to sri <hex>
# Version pinned 2026-10-02. Hashes via index SHA256 -> SRI (no prefetch needed).
let
  system = prev.stdenv.hostPlatform.system;

  version = "26.930.21537";

  sources = {
    x86_64-linux = {
      debArch = "amd64";
      hash = "sha256-YP222JXXdviDH/NaeD3gTNv6KA8PPZclhDFfmOV6olY=";
    };
    aarch64-linux = {
      debArch = "arm64";
      hash = "sha256-9kbAHuvTekkxfvYq7eh3wina7uTxyrnvPrYaHPZClWQ=";
    };
  };

  # Companion helpers inlined as store files (single-file overlay constraint).
  # Launcher: prefer native Wayland, explicit --ozone-platform flags win.
  launcherSh = prev.writeText "chatgpt-launcher.sh" ''
    #!/bin/sh
    # Prefer native rendering on scaled Wayland displays. Explicit CLI choices win.
    set -eu
    explicit_platform=false
    for arg in "$@"; do
      case "$arg" in
        --ozone-platform|--ozone-platform=*) explicit_platform=true ;;
      esac
    done
    if [ "$explicit_platform" = false ] && [ -n "''${WAYLAND_DISPLAY:-}" ] && [ "''${XDG_SESSION_TYPE:-}" != x11 ]; then
      set -- --ozone-platform=wayland "$@"
    fi
    exec @chatgpt@ "$@"
  '';

  # Plugin copy: keep modes/symlinks, restore owner writability (Nix store is r/o).
  pluginCpSh = prev.writeText "chatgpt-plugin-cp.sh" ''
    #!/bin/sh
    # Install a plugin tree copy that stays owner-writable without losing
    # executable bits or symlinks (see community chatgpt-nix plugin-cp.sh).
    set -eu

    if [ "$#" -ne 2 ]; then
      echo "usage: plugin-cp SRC DST" >&2
      exit 2
    fi

    @coreutils@/bin/cp -rT -- "$1" "$2"
    @coreutils@/bin/chmod -R u+w -- "$2"
  '';

  # ASAR patches: same-size replacements, fail on upstream drift.
  patchAsarPy = prev.writeText "chatgpt-patch-asar.py" ''
    """Apply same-size Nix compatibility patches; fail if upstream patterns change.

    The Linux plugin copy must restore owner writability without losing executables.
    Derive minified identifiers from the adjacent macOS ditto call. Equal-length
    replacements preserve ASAR file offsets; unique-match guards detect upstream drift.
    """
    import re
    import sys
    from pathlib import Path

    path = Path(sys.argv[1])
    data = path.read_bytes()

    ditto_all = list(re.finditer(
        rb"await (\w+)\(`/usr/bin/ditto`,\[`--noqtn`,\w+,\w+\]\);return", data
    ))
    if len(ditto_all) != 1:
        raise RuntimeError(
            f"ChatGPT asar patch: expected 1 darwin ditto anchor, found {len(ditto_all)}"
        )
    # 26.930: upstream also added verbatimSymlinks to the unrelated directory-copy
    # helper (codex-CLI provisioner staging / self-updater), so the plugin-copy
    # fs.cp call is no longer globally unique. The plugin-copy site is stable:
    # it sits immediately after the darwin ditto branch in the same function
    # (34 bytes away in 26.930). Anchor on the ditto match: the next such cp
    # call within a small window IS the plugin-copy fallback.
    old_matches = [
        m for m in re.finditer(
            rb"await [\w.]+\.cp\(\w+,\w+,\{recursive:!0,verbatimSymlinks:!0\}\);return",
            data,
        )
        if 0 < m.start() - ditto_all[0].end() < 200
    ]
    if len(old_matches) != 1:
        raise RuntimeError(
            "ChatGPT asar patch: expected 1 fs.cp fallback adjacent to the ditto "
            f"anchor (within 200 bytes), found {len(old_matches)}"
        )
    old = old_matches[0].group()
    args = re.match(rb"await [\w.]+\.cp\((\w+),(\w+),", old)
    new = (
        b"await "
        + ditto_all[0].group(1)
        + b"(`plugin-cp`,["
        + args.group(1)
        + b","
        + args.group(2)
        + b"]);return"
    )
    if len(new) > len(old):
        raise RuntimeError(
            f"ChatGPT asar patch: replacement ({len(new)} bytes) longer than "
            f"original ({len(old)} bytes); same-size patching no longer fits"
        )
    path.write_bytes(data.replace(old, new + b" " * (len(old) - len(new)), 1))

    # @parcel/watcher picks its native backend via detect-libc, which scans
    # the main executable for PT_INTERP. autoPatchelf moves PT_INTERP beyond
    # its 2 KiB scan range, so detection fails and the process.report fallback
    # trips Electron's CFI (SIGILL, ud1) once the Git repo watcher starts.
    # Force the glibc backend instead. Same-size replacement as above.
    # See openai/codex#38123 and NixOS/nixpkgs@8917735.
    old = b"const family = familySync();"
    new = b"const family = 'glibc'     ;"
    assert len(old) == len(new)
    data = path.read_bytes()
    if data.count(old) != 1:
        raise RuntimeError(
            "ChatGPT asar patch: expected 1 detect-libc family call, found "
            f"{data.count(old)}"
        )
    path.write_bytes(data.replace(old, new))
  '';

  linuxChatgpt = prev.stdenv.mkDerivation {
    pname = "chatgpt";
    inherit version;

    src = prev.fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${version}_${sources.${system}.debArch}.deb";
      inherit (sources.${system}) hash;
    };

    nativeBuildInputs = with prev; [
      autoPatchelfHook
      dpkg
      makeWrapper
      python3
      wrapGAppsHook3
    ];

    buildInputs = with prev; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      curl
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      libGL
      libdrm
      libgbm
      libnotify
      libpulseaudio
      libsecret
      libusb1
      libuuid
      libxcb
      libxkbcommon
      nspr
      nss
      pango
      pipewire
      stdenv.cc.cc
      systemdLibs
      # remote-control-device-key.node (26.930) links TPM2 esys/mu/tcti-device
      tpm2-tss
      wayland
      libx11
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxkbfile
      libxrandr
      libxrender
      libxshmfence
      libxscrnsaver
      libxtst
    ];

    # Libraries only dlopen'd at runtime (no NEEDED entry).
    runtimeDependencies = with prev; [
      libGL
      libnotify
      libpulseaudio
      libsecret
      libusb1
      pipewire
    ];

    # Optional/bundled-only deps, resolved per binary:
    # - libQt shims link Qt (not packaged): fail to load, Electron falls back to GTK.
    # - libc.musl-*.so.1 only needed by musl prebuilt .node files never loaded on glibc.
    # - liblog.so / libc++_shared.so only needed by android-arm64 prebuilts never loaded on Linux.
    # If autoPatchelf reports any other missing dep, package the library instead.
    autoPatchelfIgnoreMissingDeps = [
      "libQt5Core.so.5"
      "libQt5Gui.so.5"
      "libQt5Widgets.so.5"
      "libQt6Core.so.6"
      "libQt6Gui.so.6"
      "libQt6Widgets.so.6"
      "libc.musl-aarch64.so.1"
      "libc.musl-x86_64.so.1"
      "liblog.so"
      "libc++_shared.so"
    ];
    dontWrapGApps = true;

    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      runHook preUnpack
      dpkg --fsys-tarfile "$src" | tar --extract
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin"
      mv usr/lib usr/share "$out/"
      rm -rf "$out/share/lintian"

      # Keep the ASAR offsets intact; patch-asar.py checks unique matches and sizes.
      python3 ${patchAsarPy} "$out/lib/chatgpt/resources/app.asar"

      # The plugin-cp helper is resolved via PATH, like the cp call it replaces.
      install -D -m555 ${pluginCpSh} "$out/libexec/chatgpt/plugin-cp"
      substituteInPlace "$out/libexec/chatgpt/plugin-cp" \
        --replace-fail '@coreutils@' '${prev.coreutils}'

      # Upstream's usr/bin/chatgpt symlinks to lib/chatgpt/codex-launcher.
      # Our launcher selects the display backend and skips that hop;
      # codex-launcher stays in place in case the app spawns it internally.
      # PATH: bubblewrap (bundled Codex agent prefers bwrap, ships no fallback),
      # coreutils/Git/xdg-utils (also inherited by the bundled Codex terminal).
      install -D -m755 ${launcherSh} "$out/libexec/chatgpt/launcher"
      substituteInPlace "$out/libexec/chatgpt/launcher" \
        --replace-fail '@chatgpt@' "$out/lib/chatgpt/ChatGPT"
      makeWrapper "$out/libexec/chatgpt/launcher" "$out/bin/chatgpt" \
        --suffix PATH : ${
          prev.lib.makeBinPath [
            prev.bubblewrap
            prev.coreutils
            prev.gitMinimal
            prev.xdg-utils
          ]
        } \
        --suffix PATH : "$out/libexec/chatgpt" \
        --add-flags "--enable-features=WaylandWindowDecorations,WebRTCPipeWireCapturer --enable-wayland-ime=true"

      install -d "$out/share/icons/hicolor/512x512/apps"
      mv "$out/share/pixmaps/chatgpt.png" "$out/share/icons/hicolor/512x512/apps/chatgpt.png"
      rmdir "$out/share/pixmaps"

      runHook postInstall
    '';

    preFixup = ''
      wrapProgram "$out/bin/chatgpt" "''${gappsWrapperArgs[@]}"
    '';

    meta = with prev.lib; {
      description = "Official ChatGPT desktop application for Linux";
      longDescription = ''
        Unofficial Nix packaging of OpenAI's ChatGPT Linux desktop app
        (including the bundled Codex agent and terminal). The .deb's AppArmor
        profile is not applied: it hard-codes /usr/lib paths.
      '';
      homepage = "https://chatgpt.com/download/";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      license = licenses.unfree;
      platforms = builtins.attrNames sources;
      mainProgram = "chatgpt";
    };
  };
in
{
  # Shadow nixpkgs `chatgpt` on Linux only; keep darwin package elsewhere.
  chatgpt =
    if builtins.hasAttr system sources then
      linuxChatgpt
    else if prev ? chatgpt then
      prev.chatgpt
    else
      throw "chatgpt overlay: no Linux source for ${system} and no nixpkgs fallback";
}
