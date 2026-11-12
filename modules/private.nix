# Modules from the private flake inputs (nixconf-private, ai-gateway). Every
# one is gated by its own enable flag, so importing them on all hosts is inert
# until a host turns them on. Packages they need come from the matching
# nixconf-private overlays, which hosts add to `nixpkgs.overlays`.
{inputs, ...}: let
  private = inputs.nixconf-private;
in {
  flake.modules.nixos.private.imports = [
    # Local LLM stack (ollama + open-webui). ComfyUI and llm-tools are NOT gated
    # by an enable flag upstream, so the hosts that want them import them.
    private.nixosModules.llm
    # FeinTech FPS00201 press fingerprint reader + fprintd + sudo PAM.
    private.nixosModules.fingerprint-elanpress
  ];

  flake.modules.homeManager.private.imports = [
    private.homeManagerModules.openpets
    private.homeManagerModules.strata
    # OpenClaw: config, secrets wiring and autostart (needs nix-openclaw's
    # overlay, applied by the host that enables it).
    private.homeManagerModules.openclaw
    inputs.ai-gateway.homeManagerModules.default
  ];
}
