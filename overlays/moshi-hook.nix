final: prev: {
  # Prebuilt Go binary distributed from the Moshi CDN — no source archive exists.
  # Asset naming: moshi-hook_<OS>_<arch>.tar.gz, verified against the published
  # sha256 on first fetch.
  moshi-hook = let
    version = "0.4.13";
    # Per-arch sha256 (SRI) verified via `nix store prefetch-file` against
    # https://cdn.getmoshi.app/hook/v0.4.13/moshi-hook_Linux_<arch>.tar.gz
    # No upstream index exists (Homebrew formula 404 as of 2026-10-02);
    # version ceiling established by CDN path probing (0.4.14+ = 404).
    hashes = {
      x86_64 = "sha256-+3nMsexUVjhBvvfjAiTvvxXtDVL9jw4Z/oydC2LK6II=";
      arm64 = "sha256-vlgTfFJObr4sT4UWLmgvtelJ5mSWKnF9HPvPt5FIEpA=";
    };
  in
    prev.stdenv.mkDerivation {
      pname = "moshi-hook";
      inherit version;

      arch = if prev.stdenv.hostPlatform.isAarch64 then "arm64" else "x86_64";

      src = prev.fetchurl {
        url = "https://cdn.getmoshi.app/hook/v${version}/moshi-hook_Linux_${if prev.stdenv.hostPlatform.isAarch64 then "arm64" else "x86_64"}.tar.gz";
        sha256 = hashes.${if prev.stdenv.hostPlatform.isAarch64 then "arm64" else "x86_64"};
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