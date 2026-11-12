# geks-zenbook — Intel laptop, Hyprland.
# Host config is split across this directory: configuration.nix, hardware.nix,
# disk.nix (NixOS) and home.nix (Home Manager). See modules/flake/hosts.nix.
{inputs, ...}: {
  configurations.nixos.geks-zenbook = {
    module.nixpkgs.overlays = [
      inputs.nixconf-private.overlays.lmstudio
      inputs.nixconf-private.overlays.openpets
    ];

    home = {pkgs, ...}: {
      # llama-cpp-rocm + comfy-ui CLI (no enable flag upstream).
      imports = [inputs.nixconf-private.homeManagerModules.llm-tools];

      home.packages = [
        pkgs.nixconf.nix-update
        pkgs.nixconf.hypr-layout-picker
        pkgs.nixconf.specialisation-picker
        pkgs.nixconf."opencode-lmstudio-sync"
      ];
    };
  };
}
