# One formatter/linter entry point for the whole repo (treefmt-nix):
#   nix fmt              format + auto-fix everything
#   nix flake check      `checks.treefmt` fails on any unformatted/lint file
# Nix: alejandra (style) + deadnix (dead bindings) + statix (anti-patterns).
# Lua: stylua (+ selene.toml for editor linting). Shell: shellcheck + shfmt.
# Python: ruff. Indentation defaults live in .editorconfig.
{inputs, ...}: {
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true;
        deadnix.enable = true;
        statix.enable = true;
        stylua.enable = true;
        shellcheck.enable = true;
        shfmt = {
          enable = true;
          indent_size = 2;
        };
        ruff-check.enable = true;
        ruff-format.enable = true;
      };
      settings.global.excludes = [
        # Template projects are scaffolding for other repos; keep upstream style.
        "templates/**"
        "scripts/live-links-test-fixture/**"
      ];
    };
  };
}
