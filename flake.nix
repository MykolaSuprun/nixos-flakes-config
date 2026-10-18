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
    # Official Hyprland flake, tracked on main (flake.lock pins the exact rev).
    # 2026-10-14: switched from pinned tags after v0.56.2 proved unbuildable
    # against a current nixpkgs — that tag (Aug 5) predates hyprwm's gcc-16
    # stdenv migration (Aug 11), so ALL its dep pins self-build with
    # gcc15Stdenv and cannot link a gcc16 world; hand-pinning the whole
    # subtree is unmaintainable. The flake's own lock is gcc16-consistent and
    # current enough that its Hyprland loads the system mesa from
    # /run/opengl-driver. Do NOT add nixpkgs follows here: it changes the
    # derivation hash and defeats hyprland.cachix.org, and mixing Hyprland's
    # older nixpkgs/glibc with the system's newer mesa is exactly what caused
    # the 2026-10-14 login crash (gen 238: mesa 26.2.4 needs GLIBC_2.43,
    # Hyprland's June-2026 closure had glibc 2.42 → CBackend::create() abort).
    hyprland.url = "github:hyprwm/Hyprland";
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
    # qs-flow — private shell flake (vendored minflair + 3-layer settings).
    # URL is git+ssh so the private repo is fetched with the user's SSH key.
    qs-flow = {
      url = "git+ssh://git@gitlab.com/nix-private/qs-flow.git";
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

    # herdr plugin management. The manager (programs.herdr-hpm) owns herdr's
    # plugin registry declaratively: it links plugin store paths at activation
    # and prunes store links that are no longer declared. GitLab is the source
    # of truth for both repos (the GitHub mirror lags a few minutes).
    nix-herdr-manager = {
      url = "gitlab:mykolas-open/nix-herdr-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr-vimnav = {
      url = "gitlab:mykolas-open/herdr-vimnav";
      inputs.nixpkgs.follows = "nixpkgs";
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
      # nixconf-private declares its own nix-openclaw input (for standalone
      # use); dedupe it to OUR top-level input so there is exactly one
      # nix-openclaw lock entry — the overlay (pkgs.openclaw) and the private
      # HM module always come from the same pinned rev.
      inputs.nix-openclaw.follows = "nix-openclaw";

      # ⚠️  PROVISIONAL: comfyui-nix pinned to a LOCAL PATCHED FORK (2026-10-15)
      #
      # utensils/comfyui-nix upstream is stuck on ComfyUI v0.37.0 (last commit
      # 2026-09-27, no bump PR open). v0.37.0 cannot resolve alembic revision
      # 0008_drop_asset_meta, which a newer build already applied to the shared
      # user/comfyui.db — reverting caused:
      #   alembic.util.exc.CommandError: Can't locate revision identified by
      #   '0008_drop_asset_meta'
      # We therefore track ComfyUI releases ourselves at:
      #   /home/mykolas/workspaces/src/comfyui-nix-patched  (commit b623486)
      # which bumps ONLY nix/versions.nix to ComfyUI 0.40.0 + its coupled
      # wheel closure (frontend 1.55.17, templates 0.11.82, kitchen 0.2.37,
      # aimdo 0.5.6, embeddedDocs 0.5.14).
      #
      # ⚠️  REMOVE this override block once upstream releases >= 0.40.0, then
      #     `nix flake update nixconf-private` to pick it up. The fork is a
      #     single-file patch so a future upstream bump is a clean drop-in.
      inputs.comfyui-nix.url = "git+file:///home/mykolas/workspaces/src/comfyui-nix-patched";
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
