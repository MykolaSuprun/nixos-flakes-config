{inputs, ...}: {
  flake.modules.nixos.nix = {
    config,
    lib,
    ...
  }: {
    imports = [inputs.determinate.nixosModules.default];
    options.myconf.nixos.nixConf.enable = lib.mkEnableOption "nix daemon configuration";

    config = lib.mkIf config.myconf.nixos.nixConf.enable {
      # Garbage collection is handled by programs.nh.clean (sys-pkgs module).
      nix.settings = let
        cache = import ../../cache.nix;
      in {
        # No trusted-users beyond root: a trusted user can add arbitrary
        # substituters/keys or disable the sandbox, i.e. is root-equivalent —
        # and AI agents run as this user. Builds go through the root daemon.
        auto-optimise-store = true;
        # Single-sourced: cache.nix at the repo root. Listing them as trusted
        # substituters too lets flakes' nixConfig use them without trust.
        substituters = cache.trusted-substituters;
        inherit (cache) trusted-substituters;
        inherit (cache) trusted-public-keys;
      };
    };
  };
}
