# Expose each host's system closure as `checks.<system>.nixos-<host>` so
# `nix flake check` actually builds the configurations (eval-only `nix flake
# check` would not catch package/build breakage). Also provides a formatter.
# NOTE: this makes `nix flake check` heavy (it builds all hosts) — that is
# deliberate; it is the repo's CI gate.
#
# `checks.live-links` renders lib/live-links.nix exactly like real consumers do
# and runs scripts/test-live-links.sh against it (atomic ln -sfn, skip-if-
# unchanged, prefix prune, collision abort, onLink change-gating).
{self, ...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: {
    checks =
      lib.mapAttrs' (name: cfg:
        lib.nameValuePair "nixos-${name}" cfg.config.system.build.toplevel)
      self.nixosConfigurations
      // {
        live-links = let
          liveLinks = import ../lib/live-links.nix {inherit lib;};
          instance = liveLinks.mkLiveLinks {
            activationName = "liveLinksCheck";
            nixPath = ../scripts/live-links-test-fixture;
            # @LL_RUNTIME@ is substituted by the harness with its writable sandbox.
            runtimePath = "@LL_RUNTIME@";
            targetPath = "~/.config/live-links-check";
            filter = name: lib.hasSuffix ".txt" name;
            onLink = "printf 'hook\\n' >> \"$LL_HOOK_LOG\"";
          };
        in
          pkgs.runCommand "live-links-check" {} ''
            printf '%s\n' ${lib.escapeShellArg instance._script} > activation.sh
            cp -r ${../scripts/live-links-test-fixture} fixture
            bash ${../scripts/test-live-links.sh} "$PWD/activation.sh" "$PWD/fixture" "$PWD/work"
            touch $out
          '';
      };

    formatter = pkgs.nixfmt-rfc-style;
  };
}
