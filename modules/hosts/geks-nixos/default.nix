# geks-nixos — AMD desktop (7900 XTX + iGPU), Hyprland + gaming.
# Host config is split across this directory: configuration.nix, hardware.nix,
# disk.nix (NixOS) and home.nix (Home Manager). See modules/flake/hosts.nix.
{inputs, ...}: let
  # The vendored ComfyUI flake builds its own package set, independently of
  # host overlays. Extend its Python checks without changing the ROCm wheels.
  comfySource = inputs.nixconf-private.inputs.comfyui-nix.outPath;
  comfyPkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    config = {
      allowUnfree = true;
      allowBrokenPredicate = pkg: (pkg.pname or "") == "open-clip-torch";
      allowUnsupportedSystem = false;
    };
  };
  comfyVersions = import "${comfySource}/nix/versions.nix";
  comfyPythonOverrides = import "${comfySource}/nix/python-overrides.nix" {
    pkgs = comfyPkgs;
    versions = comfyVersions;
    gpuSupport = "rocm";
  };
  comfyPackage =
    (import "${comfySource}/nix/packages.nix" {
      pkgs = comfyPkgs;
      inherit (comfyPkgs) lib;
      versions = comfyVersions;
      gpuSupport = "rocm";
      pythonOverrides = comfyPkgs.lib.composeExtensions comfyPythonOverrides (_final: prev: {
        timm = prev.timm.overridePythonAttrs (old: {
          # PyTorch Inductor uses openssl to hash generated headers in the tests.
          nativeCheckInputs = (old.nativeCheckInputs or []) ++ [comfyPkgs.openssl.bin];
        });
      });
    }).default;
in {
  configurations.nixos.geks-nixos = {
    module = {
      lib,
      pkgs,
      ...
    }: {
      imports = [
        inputs.noctalia-greeter.nixosModules.default
        # ComfyUI on :8188 (utensils/comfyui-nix, prebuilt ROCm wheels) — no
        # enable flag upstream, so it is imported only here.
        inputs.nixconf-private.nixosModules.comfyui
      ];

      services.comfyui.packageSet.rocm = lib.mkForce comfyPackage;
      # Inductor also needs this executable when ComfyUI compiles at runtime.
      systemd.services.comfyui.path = [pkgs.openssl.bin];

      nixpkgs.overlays = [
        inputs.nixconf-private.overlays.lmstudio
        inputs.nixconf-private.overlays.openpets
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
      home.packages = [
        pkgs.llama-cpp-rocm
        comfyPackage
        pkgs.nixconf.nix-update
        pkgs.nixconf.hypr-layout-picker
        pkgs.nixconf."opencode-lmstudio-sync"
      ];
    };
  };
}
