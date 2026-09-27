# Minimal userspace-only build of libevdi.
#
# lian-li-linux's `lianli-evdi` crate links `-levdi` unconditionally (see its
# build.rs), so the daemon needs libevdi.so present at link AND load time even
# on hardware that never uses a virtual display (e.g. HydroShift LCD gen-1,
# UNI FAN hubs, which are all HID).
#
# nixpkgs' `evdi` derivation builds the .so *and* the DKMS kernel module, which
# drags in a full kernel-module build. We only need the userspace library, so we
# build just the `library` target. The evdi kernel module would only be needed
# for desktop-mode LCD devices (HydroShift II, Lancool 207 Digital, Universal
# Screen 8.8") and is deliberately NOT supported by this package yet.
#
# Taken from SChimera/lian-li-linux-nix (MIT) — see package.nix header.
{
  lib,
  stdenv,
  fetchFromGitHub,
  libdrm,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libevdi";
  version = "1.14.15";

  src = fetchFromGitHub {
    owner = "DisplayLink";
    repo = "evdi";
    tag = "v${finalAttrs.version}";
    # Same source/hash nixpkgs' evdi uses.
    hash = "sha256-tms+UNws+oBmwLvDFaDSIa/bUdSpK+CADodbsip3tRg=";
  };

  buildInputs = [ libdrm ];

  # The library has accumulated warnings that are errors with a modern toolchain.
  env.CFLAGS = "-Wno-error";

  # Only build the userspace library, not the kernel module or pyevdi bindings.
  buildPhase = ''
    runHook preBuild
    make -C library
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/include
    # Copy the .so and any versioned/soname symlinks the build produced.
    cp -P library/libevdi.so* $out/lib/
    cp library/evdi_lib.h $out/include/ 2>/dev/null || true
    runHook postInstall
  '';

  meta = {
    description = "Userspace library from DisplayLink/evdi (no kernel module)";
    homepage = "https://github.com/DisplayLink/evdi";
    license = with lib.licenses; [
      lgpl21Plus
      mit
    ];
    platforms = lib.platforms.linux;
  };
})
