# Temporary workarounds for packages broken at the locked nixpkgs rev
# (f4a03c0, 2026-11). Drop each entry once a nixpkgs bump builds it again.
_final: prev: {
  # The new Cargo setup hook forces undeclared system libraries (first zstd)
  # into Herdr Desktop too. Its vendor tree already supplies those libraries.
  herdr-desktop = prev.herdr-desktop.overrideAttrs (_: {
    dontCargoUseSystemLibs = true;
  });

  # The new cargo-setup-hook (cargoUseSystemLibs) forces system aws-lc, zstd,
  # oniguruma, libgit2, ... for every Rust package, but codex 0.167.0 only
  # provides openssl. Unset the toggles so the crates build their vendored
  # copies again, as they did before the hook change.
  codex = prev.codex.overrideAttrs (old: {
    preBuild =
      (old.preBuild or "")
      + ''
        unset AWS_LC_SYS_USE_SYSTEM ZSTD_SYS_USE_PKG_CONFIG RUSTONIG_SYSTEM_LIBONIG \
          LIBGIT2_NO_VENDOR LIBSSH2_SYS_USE_PKG_CONFIG LIBSQLITE3_SYS_USE_PKG_CONFIG \
          SODIUM_USE_PKG_CONFIG SYSTEM_DEPS_BUILD_INTERNAL JEMALLOC_OVERRIDE \
          DUCKDB_DOWNLOAD_LIB DUCKDB_INCLUDE_DIR NGINX_SOURCE_DIR
      '';
  });
}
