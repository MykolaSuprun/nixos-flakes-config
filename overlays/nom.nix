# TEMP overlay: nom 2.2.0 vs Determinate Nix 3.23.x internal-json.
#
# Determinate's PR #615 (in 3.23.0+) added "stringly" OTel activities —
# type 10113 (CopySourcePath / HashSourcePath / EvaluateFlakeDerivationOutput,
# ~138 events per host toplevel eval; result type 10111 is coming too).
# nom 2.2.0 (latest release, 2026-07-28) whitelists activity types 0/100-112
# and hard-errors PER EVENT instead of skipping unknowns — so every
# `nixos-build` run spews `ParseNixJSONMessageError ... invalid activity
# type: 10113` lines (non-fatal, exit 0). Reproduced locally 2026-10-11
# (`nix build --dry-run --log-format internal-json | nom --json` → 138).
#
# Fix = upstream nom patch #321 "fix(json): handle unknown activity and
# result types gracefully" (OpenType Int / OtherResult Int fallback).
#
# Scope: rebuilds nom + its wrappers (nh) only — nixpkgs' nom package.nix
# exposes extraComposeFunctions precisely so overlays can patch it without
# touching the Haskell package set.
#
# REMOVE this overlay when the root nixpkgs ships a nom with #321 merged.
# nixpkgs 3ec6363 (2026-10-23) DOES carry its own commit-pinned copy — with
# that rev this overlay would double-apply, so delete this file there.
#
# 2026-10-26 — WHY THE PATCH IS VENDORED INTO patches/:
# this overlay used to `fetchpatch2` the LIVE url
# https://github.com/maralorn/nix-output-monitor/pull/321.diff. GitHub
# regenerates PR diffs when the PR is merged/updated, so the bytes changed
# under the pinned hash and the build died with
#   hash mismatch ... specified sha256-8nMjLaL03LL02... got sha256-fOS80YxNS7...
# A fixed-output derivation must never track a mutable URL. The patch now
# lives in patches/nom-pr321-unknown-activity-types.patch — apply it with
# -p1 and it can never drift again. To re-sync from upstream:
#   curl -sL https://github.com/maralorn/nix-output-monitor/pull/321.diff \
#     -o patches/nom-pr321-unknown-activity-types.patch
#
# Upstream trail: maralorn/nix-output-monitor#320 (issue) #321 (fix),
# DeterminateSystems/nix-src#615 (10113) #659 (fork-side tracking).
final: prev: {
  nix-output-monitor = prev.nix-output-monitor.override (old: {
    extraComposeFunctions = (old.extraComposeFunctions or [ ]) ++ [
      (final.haskell.lib.compose.overrideCabal {
        # The Haskell builder sets sourceRoot to <src>/nix-output-monitor, so
        # the vendored patch's `a/nix-output-monitor/lib/...` prefixes need
        # two levels stripped. generic-builder has no `patchFlags` arg, so the
        # strip level is spelled out here (the old `fetchpatch stripLen = 1`
        # worked differently: it rewrote paths BEFORE unpacking).
        postPatch = (old.postPatch or "") + ''
          patch -p2 -i ${../patches/nom-pr321-unknown-activity-types.patch}
        '';
      })
    ];
  });
}
