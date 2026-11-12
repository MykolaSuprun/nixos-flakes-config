_final: prev: {
  # Prebuilt Go binary distributed from the Moshi CDN — no source archive exists.
  # Asset naming: moshi-hook_<OS>_<arch>.tar.gz, verified against the published
  # sha256 on first fetch.
  moshi-hook = let
    version = "0.4.53";
    # Per-arch sha256 (SRI) verified via `nix store prefetch-file` against
    # https://cdn.getmoshi.app/hook/v0.4.53/moshi-hook_Linux_<arch>.tar.gz
    # No upstream index exists; the CDN is the only distribution channel.
    # Bumping: resolve the live version from
    #   curl -s https://cdn.getmoshi.app/hook/latest/version.txt
    # (that file is what https://getmoshi.app/install.sh reads), then
    # prefetch both arches. The CDN keeps only a few recent versions: 0.4.13
    # (2026-10-26) and 0.4.45 (2026-11-10) were 404 on every arch — the
    # CDN dropped it and the cached FOD was GC'd, so the pinned URL must be
    # bumped rather than assumed stable.
    hashes = {
      x86_64 = "sha256-kKs5brM+rY0u6Wei3BUI0HrbdJTYsLZKS58PCjWoI0Y=";
      arm64 = "sha256-RdbZ9o2Yo8oVZ7LYFqNcdSPln3ulbALCJa9djBC8BEY=";
    };
  in
    prev.stdenv.mkDerivation {
      pname = "moshi-hook";
      inherit version;

      arch =
        if prev.stdenv.hostPlatform.isAarch64
        then "arm64"
        else "x86_64";

      src = prev.fetchurl {
        url = "https://cdn.getmoshi.app/hook/v${version}/moshi-hook_Linux_${
          if prev.stdenv.hostPlatform.isAarch64
          then "arm64"
          else "x86_64"
        }.tar.gz";
        sha256 =
          hashes.${
            if prev.stdenv.hostPlatform.isAarch64
            then "arm64"
            else "x86_64"
          };
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
