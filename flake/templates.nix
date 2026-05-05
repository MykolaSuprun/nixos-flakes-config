# Flake-parts module: expose per-language devShell templates.
# Templates live under templates/<name>/ at the repo root.
# Auto-discovered by import-tree ./flake — no manual registration needed.
{...}: {
  flake.templates = {
    python-uv = {
      path = ../templates/python-uv;
      description = "Python development environment with uv";
    };
    go = {
      path = ../templates/go;
      description = "Go development environment with gopls and delve";
    };
    haskell = {
      path = ../templates/haskell;
      description = "Haskell development environment with GHC and cabal";
    };
    java = {
      path = ../templates/java;
      description = "Java development environment with JDK 21 and Maven";
    };
    scala = {
      path = ../templates/scala;
      description = "Scala development environment with JDK 21 and Mill";
    };
  };
}
