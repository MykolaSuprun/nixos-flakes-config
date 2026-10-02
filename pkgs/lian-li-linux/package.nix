# lian-li-linux: open-source Linux replacement for L-Connect 3.
# Builds the daemon (HID/USB device control) and the Tauri v2 + Vue GUI.
#
# Packaging structure adapted from SChimera/lian-li-linux-nix (MIT), reworked
# for upstream v1.1.4 which switched the frontend toolchain from bun to npm:
#  - frontend deps are prefetched with fetchNpmDeps (fixed-output npm cache)
#  - `npm ci --offline && npm run build` runs in preBuild; the src-tauri
#    build.rs verifies the stamped dist/ manifest and then skips its own
#    npm invocation entirely (v1.1.4 has no LIANLI_NO_FRONTEND escape hatch)
#  - udev rules moved to packaging/udev/60-lianli.rules (GROUP="lianli")
# Devices relevant here: HydroShift LCD gen-1 AIO (0416:7399, HID, 480x480),
# UNI FAN SL V2 hub (0cf2:a105). Desktop-mode LCD devices (HydroShift II,
# Lancool 207, Universal Screen) would also need the evdi kernel module —
# intentionally out of scope.
{
  lib,
  stdenvNoCC,
  rustPlatform,
  fetchFromGitHub,
  callPackage,
  cacert,
  pkg-config,
  cmake,
  nasm,
  makeWrapper,
  wrapGAppsHook3,
  nodejs,
  coreutils,
  # link/runtime libraries
  udev,
  libusb1,
  ffmpeg,
  fontconfig,
  freetype,
  libjpeg_turbo,
  libdrm,
  # tauri / webkit stack
  webkitgtk_4_1,
  gtk3,
  glib,
  libsoup_3,
  librsvg,
  libayatana-appindicator,
}:
let
  libevdi = callPackage ./libevdi.nix { };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "lianli-linux";
  version = "1.1.5";

  src = fetchFromGitHub {
    owner = "sgtaziz";
    repo = "lian-li-linux";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true; # vendored tinyuz + HDiffPatch C++ live in submodules
    hash = "sha256-8D1ru/T1tlcRtx5FYfhVIKlzIbFDBOIp4fklnCTwupg=";
  };

  # Vue frontend dependencies: node_modules produced by a fixed-output
  # derivation. FODs may use the network, so `npm ci` runs there (a
  # tarball-only prefetch cache breaks `npm ci --offline` — npm still wants
  # registry packuments, e.g. vue-tsc ENOTCACHED); the main build gets the
  # finished node_modules and stays fully offline.
  # Lockfile: crates/lianli-gui/package-lock.json.
  guiNodeModules = stdenvNoCC.mkDerivation {
    pname = "lianli-linux-gui-node-modules";
    inherit (finalAttrs) version src;
    # cacert: the sandbox has no CA bundle; npm (node) reads SSL_CERT_FILE.
    nativeBuildInputs = [ nodejs cacert ];

    buildPhase = ''
      runHook preBuild
      cd crates/lianli-gui
      export HOME=$TMPDIR
      npm ci --no-audit --no-fund --ignore-scripts
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -R node_modules $out/
      runHook postInstall
    '';

    dontFixup = true;
    outputHashMode = "recursive";
    outputHash = "sha256-45bdkHmGDt6yF5WPTvd4zYrSoxQXlrN0Cw2wMhaKW4U=";
  };

  cargoLock.lockFile = finalAttrs.src + "/Cargo.lock";

  nativeBuildInputs = [
    pkg-config
    cmake # turbojpeg-sys builds libjpeg-turbo via cmake
    nasm # ...which needs nasm for SIMD
    makeWrapper
    wrapGAppsHook3 # gsettings schemas etc. for the webkit GUI
    nodejs # npm ci + vite build for the Vue frontend (offline via npmDeps)
    rustPlatform.bindgenHook # ffmpeg-sys-next uses bindgen (sets LIBCLANG_PATH)
  ];

  # cmake is only a build tool for a -sys crate; there is no top-level
  # CMakeLists.txt, so don't let the cmake hook hijack the configure phase.
  dontUseCmakeConfigure = true;

  buildInputs = [
    udev # hidapi (hidraw backend) + device enumeration
    libusb1 # rusb
    ffmpeg # ffmpeg-next (libav*)
    fontconfig
    freetype
    libjpeg_turbo # turbojpeg
    libdrm
    libevdi # lianli-evdi links -levdi unconditionally
    # Tauri v2 webview stack
    webkitgtk_4_1
    gtk3
    glib
    libsoup_3
    librsvg
  ];

  postPatch = ''
    # Upstream pins a rustup toolchain channel; nix supplies its own rustc and
    # ignores the file, but removing it avoids any confusion/warnings.
    rm -f rust-toolchain.toml

    # The frontend is built manually in preBuild (below); make sure nothing in
    # the cargo build can kick off a networked npm run.
    substituteInPlace crates/lianli-gui/src-tauri/tauri.conf.json \
      --replace-fail '"beforeBuildCommand": "npm run build"' '"beforeBuildCommand": ""' \
      --replace-fail '"beforeDevCommand": "npm run dev"' '"beforeDevCommand": ""'

    # FHS hardcodings in the health/diagnostic helpers: /usr/bin/systemctl and
    # /usr/bin/journalctl don't exist on NixOS (only /bin/sh, via binsh), so
    # every spawned diagnostic failed with ENOENT ("Starting diagnostic
    # command: No such file or directory"). Point them at profile paths.
    # (1.1.5 upstream made helper PATH inherit the caller env and dropped the
    # /bin/cat and absolute-ffmpeg hardcodes — those substitutions are gone.)
    substituteInPlace crates/lianli-control/src/account.rs \
      --replace-fail '"/usr/bin/systemctl"' '"/run/current-system/sw/bin/systemctl"'
    substituteInPlace crates/lianli-control/src/diagnostic_logs.rs \
      --replace-fail '"/usr/bin/systemctl"' '"/run/current-system/sw/bin/systemctl"' \
      --replace-fail '"/usr/bin/journalctl"' '"/run/current-system/sw/bin/journalctl"'
  '';

  # Build the frontend dist/ from the prefetched node_modules. The src-tauri
  # build.rs then verifies the stamped manifest and skips its own npm run.
  # Mirrors upstream's `npm run build` (vue-tsc --noEmit && vite build && node
  # scripts/stamp-build.mjs), but invokes the tools with node directly: the
  # node_modules/.bin shims use `#!/usr/bin/env node` shebangs and /usr/bin/env
  # does not exist in the sandbox.
  preBuild = ''
    cp -R ${finalAttrs.guiNodeModules}/node_modules crates/lianli-gui/node_modules
    chmod -R u+w crates/lianli-gui/node_modules
    (
      cd crates/lianli-gui
      export HOME=$TMPDIR
      node node_modules/vue-tsc/bin/vue-tsc.js --noEmit
      node node_modules/vite/bin/vite.js build
      node scripts/stamp-build.mjs
    )
  '';

  # Tests touch real hardware / sockets; skip in the sandbox.
  doCheck = false;

  postInstall = ''
    # udev rules — picked up by services.udev.packages = [ pkg ].
    # The rules reference GROUP="lianli" (created by the NixOS module).
    install -Dm644 packaging/udev/60-lianli.rules \
      $out/lib/udev/rules.d/60-lianli.rules
    # (1.1.4 substituted /bin/chmod in the evdi rule here; 1.1.5 rewrote it to
    # /bin/sh -c 'exec chmod ...' — /bin/sh exists on NixOS, and the chmod only
    # matters for evdi desktop-mode LCDs, deliberately out of scope here.)

    # systemd user unit (for non-NixOS use; the NixOS module defines its own)
    install -Dm644 packaging/systemd/lianli-daemon.service \
      $out/lib/systemd/user/lianli-daemon.service
    substituteInPlace $out/lib/systemd/user/lianli-daemon.service \
      --replace-fail /usr/bin/lianli-daemon $out/bin/lianli-daemon

    # desktop entry + icons
    install -Dm644 packaging/desktop/*.desktop -t $out/share/applications/
    install -Dm644 assets/icons/32x32.png \
      $out/share/icons/hicolor/32x32/apps/com.sgtaziz.lianlilinux.png
    install -Dm644 assets/icons/128x128.png \
      $out/share/icons/hicolor/128x128/apps/com.sgtaziz.lianlilinux.png
    install -Dm644 "assets/icons/128x128@2x.png" \
      $out/share/icons/hicolor/256x256/apps/com.sgtaziz.lianlilinux.png
    install -Dm644 assets/icons/icon.svg \
      $out/share/icons/hicolor/scalable/apps/com.sgtaziz.lianlilinux.svg
  '';

  # tray-icon dlopens libayatana-appindicator at runtime rather than linking it.
  # The daemon shells out to ffprobe/ffmpeg (fps probe, video decode, h264
  # scaling, pixel cleaning) by bare name — wrap it with ffmpeg on PATH so it
  # works under the bare systemd user-service environment.
  postFixup = ''
    wrapProgram $out/bin/lianli-gui \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libayatana-appindicator ]}"
    wrapProgram $out/bin/lianli-daemon \
      --prefix PATH : "${lib.makeBinPath [ ffmpeg ]}"
  '';

  passthru = { inherit libevdi; };

  meta = {
    description = "Open-source Linux replacement for L-Connect 3 — fan/RGB control and LCD streaming for Lian Li devices";
    homepage = "https://github.com/sgtaziz/lian-li-linux";
    license = lib.licenses.mit;
    mainProgram = "lianli-gui";
    platforms = [ "x86_64-linux" ];
  };
})
