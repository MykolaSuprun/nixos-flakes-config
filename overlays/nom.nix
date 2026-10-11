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
# Open/unmerged upstream as of 2026-10-11 and user-validated in the wild;
# no nom release > 2.2.0 and no nixpkgs backport exist yet.
#
# Scope: rebuilds nom + its wrappers (nh) only — nixpkgs' nom package.nix
# exposes extraComposeFunctions precisely so overlays can patch it without
# touching the Haskell package set.
#
# REMOVE this overlay when nixpkgs ships a nom with #321 merged (check
# https://code.maralorn.de/maralorn/nix-output-monitor/releases and the
# nixpkgs by-name bump; search this repo for "nom 10113" flag).
#
# Upstream trail: maralorn/nix-output-monitor#320 (issue) #321 (fix),
# DeterminateSystems/nix-src#615 (10113) #659 (fork-side tracking).
final: prev: {
  nix-output-monitor = prev.nix-output-monitor.override (old: {
    extraComposeFunctions = (old.extraComposeFunctions or [ ]) ++ [
      (final.haskell.lib.compose.overrideCabal {
        patches = [
          (prev.fetchpatch2 {
            url = "https://github.com/maralorn/nix-output-monitor/pull/321.diff";
            stripLen = 1;
            hash = "sha256-8nMjLaL03LL02etLs5h6CHKeSRUvW0WYUAirTFng4+E=";
          })
        ];
      })
    ];
  });
}
