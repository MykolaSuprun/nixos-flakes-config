# `overlays.default`: every overlay in ../../overlays, plus two attribute sets
# that replace the old specialArgs:
#   pkgs.stable  — nixpkgs-stable instance (same unfree policy)
#   pkgs.nixconf — this flake's own CLI packages (perSystem.packages)
{
  inputs,
  lib,
  withSystem,
  ...
}: let
  repoOverlays = import ../../overlays;

  flakeOverlay = _final: prev: let
    inherit (prev.stdenv.hostPlatform) system;
  in {
    stable = import inputs.nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
      # winboat (from pkgs.stable) pulls stable's electron-40.10.5, which
      # nixpkgs marks insecure. Scoped to the stable instance only — the main
      # pkgs instance needs no exemption. Drop when winboat's stable Electron
      # advances past the insecure window.
      config.permittedInsecurePackages = ["electron-40.10.5"];
    };
    nixconf = withSystem system ({config, ...}: config.packages);
  };
in {
  flake.overlays.default = lib.composeManyExtensions (repoOverlays ++ [flakeOverlay]);
}
