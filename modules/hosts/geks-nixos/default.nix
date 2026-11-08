# geks-nixos — AMD desktop (7900 XTX + iGPU), Hyprland + gaming.
# Host config is split across this directory: configuration.nix, hardware.nix,
# disk.nix (NixOS) and home.nix (Home Manager). See modules/flake/hosts.nix.
{inputs, ...}: {
  configurations.nixos.geks-nixos = {
    module = {
      imports = [
        inputs.noctalia-greeter.nixosModules.default
        # ComfyUI on :8188 (utensils/comfyui-nix, prebuilt ROCm wheels) — no
        # enable flag upstream, so it is imported only here.
        inputs.nixconf-private.nixosModules.comfyui
      ];

      nixpkgs.overlays = [
        inputs.nixconf-private.overlays.lmstudio
        inputs.nixconf-private.overlays.openpets
        inputs.nixconf-private.overlays.chatgpt
        inputs.nixconf-private.overlays.strata
        # OpenClaw packaging fix (nodejs-24 prebuilt tarball repaired with
        # patchelf 0.15.2). Must come BEFORE nix-openclaw's overlay: it
        # supplies the repaired pkgs.nodejs_24 that nix-openclaw's version
        # guard then returns instead of rebuilding its broken tarball.
        inputs.nixconf-private.overlays.openclaw
        # First-party OpenClaw package consumed by the private HM module;
        # nixpkgs' own openclaw stays marked insecure.
        inputs.nix-openclaw.overlays.default
      ];
    };

    home = {pkgs, ...}: {
      # llama-cpp-rocm + comfy-ui CLI (no enable flag upstream).
      imports = [inputs.nixconf-private.homeManagerModules.llm-tools];

      home.packages = [
        pkgs.nixconf.nix-update
        pkgs.nixconf.hypr-layout-picker
        pkgs.nixconf."opencode-lmstudio-sync"
      ];
    };
  };
}
