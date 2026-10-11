{
  description = "NixOS flake";

  # Substituters/keys are single-sourced in cache.nix (repo root) for all
  # NixOS/installer consumers. nixConfig CANNOT import it: nix refuses thunked
  # nixConfig values, so this literal list must be kept in sync with cache.nix.
  nixConfig = {
    experimental-features = ["nix-command" "flakes"];
    trusted-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      "https://install.determinate.systems"
      "https://noctalia.cachix.org"
      "https://comfyui.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "cache.flakehub.com-4:Asi8qIv291s0aYLyH6IOnr5Kf6+OF14WVjkE6t3xMio="
      "cache.flakehub.com-5:zB96CRlL7tiPtzA9/WKyPkp3A2vqxqgdgyTVNGShPDU="
      "cache.flakehub.com-6:W4EGFwAGgBj3he7c5fNh9NkOXw0PUVaxygCVKeuvaqU="
      "cache.flakehub.com-7:mvxJ2DZVHn/kRxlIaxYNMuDG1OvMckZu32um1TadOR8="
      "cache.flakehub.com-8:moO+OVS0mnTjBTcOUh2kYLQEd59ExzyoW1QgQ8XAARQ="
      "cache.flakehub.com-9:wChaSeTI6TeCuV/Sg2513ZIM9i0qJaYsF+lZCXg0J6o="
      "cache.flakehub.com-10:2GqeNlIp6AKp4EF2MVbE1kBOp9iBSyo0UPR9KoR0o1Y="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
    ];
  };

  inputs = {
    # Core
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
    # opencode V1 retired 2026-09-29: the former nixpkgs-opencode-pin input
    # (and its host pin overlay) are gone — overlays/opencode.nix builds V2
    # from the official npm prebuilt, so no pinned nixpkgs is needed.
    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dendritic infrastructure
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    # Platform-specific
    # follows is safe here: NixOS-WSL is a module-only flake with no binary
    # cache — dedup avoids a second nixpkgs download (verified 2026-09-20).
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
      flake = true;
    };

    # Desktop
    impurity.url = "github:outfoxxed/impurity.nix";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Theming framework — fills in GTK and app targets not covered by catppuccin-nix
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland/v0.55.4"; # Or the exact tag name, e.g., "v0.55.4"
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    # Pin the cachix branch (always the latest cached commit) and do NOT follow
    # nixpkgs — following changes the derivation hash and defeats the binary cache.
    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sysc-greet = {
      url = "github:Nomadcxx/sysc-greet";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Theming
    catppuccin.url = "github:catppuccin/nix";

    # Tools
    my-nixvim = {
      url = "gitlab:mykolas-open/nixvim-config";
      flake = true;
    };

    # Dev environment picker TUI (vim-keyed nix develop / flake template scaffolder)
    flake-env = {
      url = "gitlab:mykolas-open/flake-env";
      flake = true;
    };

    # Disk partitioning
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixconf-private = {
      url = "git+ssh://git@gitlab.com/nix-private/nixconf-private.git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    # OpenClaw — first-party Nix distribution (official openclaw org flake).
    # Chosen over nixpkgs' package: that one is permanently marked insecure
    # (LLM prompt-injection policy flag, not a patchable CVE; nixpkgs
    # maintainer confirmed no fix without the permit). This flake ships the
    # same upstream app unmarked, newer, with a deterministic Nix-mode
    # runtime. nixpkgs follows ours — the overlay feeds OUR pkgs instance
    # (applied in flake/hosts/geks-nixos/default.nix).
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;}
    (inputs.import-tree ./flake);
}
