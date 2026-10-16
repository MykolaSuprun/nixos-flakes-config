{
  inputs,
  pkgs,
  config,
  lib,
  useHyprlandFlake ? false,
  ...
}: let
  hypr_pkgs =
    if useHyprlandFlake
    then inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}
    else pkgs;
in {
  options = {
    hyprconf = {
      # Read by the HM hyprland modules (settings.nix) to pick host-specific
      # monitor/GPU values. NOTE: the option is declared separately in the NixOS
      # and HM namespaces — keep both decls in sync.
      target = lib.mkOption {
        type = lib.types.enum ["geks-zenbook" "geks-nixos"];
        default = "geks-nixos";
        description = "Target system determining hyprland configuration variant";
        example = "geks-zenbook";
      };
      hyprland = {
        enable = lib.mkEnableOption "enables hyprland config";
      };
    };
  };
  config = lib.mkIf config.hyprconf.hyprland.enable {
    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;
        # Wrap the package's start-hyprland: greetd/Noctalia sessions launch
        # start-hyprland DIRECTLY (bypassing uwsm), so the uwsm-only
        # AQ_DRM_DEVICES env never applied and the compositor silently rendered
        # on the dGPU. The wrapper sources the shared render-GPU picker
        # (~/.config/hypr/render-gpu-env.sh, HM-managed) which sets
        # AQ_DRM_DEVICES iGPU-first (default) or dGPU-first (user switch).
        package = let
          hypr-wrapped = pkgs.symlinkJoin {
            name = "hyprland-render-gpu-wrapped";
            version = hypr_pkgs.hyprland.version;
            paths = [hypr_pkgs.hyprland];
            nativeBuildInputs = [pkgs.makeWrapper];
            postBuild = ''
              mv $out/bin/start-hyprland $out/bin/.start-hyprland-unwrapped
              makeWrapper $out/bin/.start-hyprland-unwrapped $out/bin/start-hyprland \
                --run '[ -f "$HOME/.config/hypr/render-gpu-env.sh" ] && . "$HOME/.config/hypr/render-gpu-env.sh" || true'
            '';
          };
          # The nixpkgs hyprland module introspects `override` (genFinalPackage)
          # and re-applies { enableXWayland }: return the FULL merged value
          # (self-referential) so meta/providedSessions/override survive the
          # module's plumbing. meta passthrough keeps lib.getExe pointing at
          # bin/Hyprland (capital H); providedSessions satisfies sessionPackages.
          final = hypr-wrapped
            // {
              override = {enableXWayland ? true}: final;
              # meta passthrough for mainProgram (lib.getExe → bin/Hyprland),
              # but pin outputsToInstall to `out`: the original lists "man"
              # too, and man-db's buildenv resolves drv.man → missing here.
              meta = hypr_pkgs.hyprland.meta // {outputsToInstall = ["out"];};
              providedSessions = hypr_pkgs.hyprland.providedSessions or ["hyprland"];
            };
        in
          final;
        portalPackage = hypr_pkgs.xdg-desktop-portal-hyprland;
        xwayland.enable = true;
      };
      uwsm = {
        enable = true;
      };
    };

    services = {
      dbus.implementation = "broker";
    };
  };
}
