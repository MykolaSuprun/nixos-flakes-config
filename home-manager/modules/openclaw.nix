# OpenClaw (first-party nix-openclaw). nixpkgs' own openclaw package is
# permanently marked insecure (LLM prompt-injection policy flag, not a
# patchable CVE — the nixpkgs maintainer confirmed there is no fix without
# the permit), so the official openclaw-org flake provides the package
# instead. Host requirement: inputs.nix-openclaw.overlays.default must be
# applied to pkgs (done in flake/hosts/geks-nixos/default.nix) — the
# upstream module resolves its default package from pkgs.openclaw /
# pkgs.openclawPackages (which only the overlay provides unmarked).
{
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];

  options.myconf.openclaw.enable = lib.mkEnableOption "OpenClaw AI assistant (first-party nix-openclaw)";

  config = lib.mkIf config.myconf.openclaw.enable {
    programs.openclaw = {
      enable = true;
      # The gateway systemd unit (openclaw-gateway, Restart=always) is defined
      # but deliberately not autostarted: it needs configuration first
      # (gateway auth token + a channel under programs.openclaw.config; Nix
      # mode forbids runtime self-mutation). To autostart once configured:
      #   systemd.user.services.openclaw-gateway.Install.WantedBy = ["default.target"];
    };
  };
}
