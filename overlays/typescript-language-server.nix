# TEMP overlay: typescript-language-server 6.0.2 pnpm-deps hash mismatch.
#
# nixpkgs bump 7191cc1b (2026-10-09) rewrote the package around fetchPnpmDeps
# (upstream tsserver moved yarn → pnpm in 6.0.0) but pinned a hash that doesn't
# reproduce: a fresh pnpm fetch yields
#   sha256-xR/EF60lVBsITKgH7wCM2wHM46PFQevD51KfCENSUH4=
# while the pinned hash is sha256-MUSxDMlb… → FOD hash mismatch → tsserver and
# every dependent closure (system-path, man-paths, home-manager-path, …) fail
# with "1 dependency failed" (19 cascade errors, killed nixos-build 2026-10-14).
#
# Upstream fixed it in ac7b1aae "typescript-language-server: fix pnpm hash"
# (2026-10-11 20:28 UTC) — pinning exactly the hash used below (verified
# byte-identical to this machine's failed-build output, so the value is not a
# guess). FlakeHub's unstable snapshots still resolve pre-fix (0.1.1090327 =
# 7fd4004, 2026-10-11 15:54 UTC), so the fix cannot be locked yet.
#
# Scope: rebuilds the tsserver pnpm-deps FOD + tsserver only.
#
# REMOVE this overlay once FlakeHub publishes a post-ac7b1aae 0.1 snapshot and
# the lock advances past it (`nix flake update nixpkgs`) — search this repo for
# "tsserver pnpm" flag.
#
# Upstream trail: NixOS/nixpkgs 7191cc1b (broken bump) → ac7b1aae (fix).
final: prev: {
  typescript-language-server = prev.typescript-language-server.overrideAttrs (old: {
    pnpmDeps = old.pnpmDeps.overrideAttrs (_: {
      outputHash = "sha256-xR/EF60lVBsITKgH7wCM2wHM46PFQevD51KfCENSUH4=";
    });
  });
}
