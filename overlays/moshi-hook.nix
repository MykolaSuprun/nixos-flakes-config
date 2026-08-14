final: prev: {
  # Prebuilt Go binary distributed from the Moshi CDN — no source archive exists.
  # Asset naming: moshi-hook_<OS>_<arch>.tar.gz, verified against the published
  # sha256 on first fetch.
  moshi-hook = prev.stdenv.mkDerivation rec {
    pname = "moshi-hook";
    version = "0.2.76";

    arch = if prev.stdenv.hostPlatform.isAarch64 then "arm64" else "x86_64";

    src = prev.fetchurl {
      url = "https://cdn.getmoshi.app/hook/v${version}/moshi-hook_Linux_${arch}.tar.gz";
      sha256 = "sha256-PBPEeCsFgBKFFLjrVM5SpL4kWhwzs7JGO0DjUHEMM5I=";
    };

    dontStrip = true; # already stripped upstream Go binary
    dontPatchELF = true; # statically linked — nothing to patch
    dontConfigure = true;
    sourceRoot = "."; # keep archive root: binary sits next to docs/

    installPhase = ''
      runHook preInstall
      install -Dm755 moshi-hook "$out/bin/moshi-hook"
      ln -s moshi-hook "$out/bin/moshi"
      runHook postInstall
    '';

    meta = with prev.lib; {
      description = "Portable daemon and CLI for Moshi: agent hooks, local socket bridge, host gateway";
      homepage = "https://getmoshi.app";
      license = licenses.unfree;
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  };
}