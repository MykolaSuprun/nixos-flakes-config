# Expose each host's system closure as `checks.<system>.nixos-<host>` so
# `nix flake check` actually builds the configurations (eval-only `nix flake
# check` would not catch package/build breakage). Also provides a formatter.
# NOTE: this makes `nix flake check` heavy (it builds all hosts) — that is
# deliberate; it is the repo's CI gate.
{self, ...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: {
    checks =
      lib.mapAttrs' (name: cfg:
        lib.nameValuePair "nixos-${name}" cfg.config.system.build.toplevel)
      self.nixosConfigurations;

    formatter = pkgs.nixfmt-rfc-style;
  };
}
