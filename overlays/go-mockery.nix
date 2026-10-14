# TEMP overlay: go-mockery 3.8.0 is incompatible with the go-1.27 toolchain.
#
# nixpkgs 7fd4004 ships go 1.27.2, whose stdlib export data is version 5;
# 3.8.0's vendored golang.org/x/tools reader caps at version 4. Both
# mockery's own tests AND any package whose build invokes mockery die with
#   cannot decode "os/exec", export data version 5 is greater than maximum
#   supported version 4
# sesh (pkgs/by-name/se/sesh: buildGo127Module + preBuild = "mockery") pulls
# mockery in as a nativeBuildInput, so the failure killed nixos-build
# 2026-10-14 — first as mockery's own checkPhase, then as sesh's buildPhase
# once doCheck=false.
#
# Fix = upstream go-mockery 3.8.1 (NixOS/nixpkgs 650d560a, 2026-10-12), whose
# vendored x/tools reads the new export data. The packaging below is upstream
# 650d560a's package.nix pruned to build-only (Taskfile e2e suite dropped,
# doCheck=false — nixpkgs hydra validates the tests; the temp build only
# needs the binary). MUST go through callPackage (makeOverridable): sesh
# swaps the builder via `go-mockery.override { buildGoModule =
# buildGo127Module; }`, which needs the package-expression-level override —
# a raw buildGoModule result has no `.override` (hit for real 2026-10-14).
# FlakeHub's unstable snapshots still resolve pre-bump (0.1.1090327 =
# 7fd4004, 2026-10-11 15:54 UTC), so the fixed version cannot be locked yet.
#
# Scope: rebuilds go-mockery, and sesh (which re-builds it with
# buildGo127Module via .override).
#
# REMOVE together with overlays/typescript-language-server.nix once FlakeHub
# publishes a post-650d560a 0.1 snapshot and the lock advances past it
# (`nix flake update nixpkgs`) — search this repo for "mockery 201" flag.
#
# Upstream trail: NixOS/nixpkgs 650d560a (go-mockery 3.8.0 -> 3.8.1).
final: prev: {
  go-mockery = prev.callPackage (
    {
      lib,
      buildGoModule,
      fetchFromGitHub,
    }:
    buildGoModule (finalAttrs: {
      pname = "go-mockery";
      version = "3.8.1";

      src = fetchFromGitHub {
        owner = "vektra";
        repo = "mockery";
        tag = "v${finalAttrs.version}";
        hash = "sha256-HCbnifYWE/3CG85dt0FPWT9hLSQbgOXuOKTBJHO0S2U=";
      };

      proxyVendor = true;
      vendorHash = "sha256-ksfAHdPdOd8ELS0CSBg+E7KPd5xX/uGeLPn9HiItjdI=";

      ldflags = [
        "-s"
        "-w"
        "-X github.com/vektra/mockery/v${lib.versions.major finalAttrs.version}/internal/logging.SemVer=v${finalAttrs.version}"
      ];

      env = {
        CGO_ENABLED = "0";
        GOWORK = "off";
      };

      subPackages = [ "." ];

      doCheck = false;
    })
  ) { };
}
