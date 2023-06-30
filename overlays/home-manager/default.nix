args:
  # import all nix files in the current folder, and execute them with args as parameters
  # The return value is a list of all execution results, which is the list of overlays
  builtins.map
  (f: (import (./. + "/${f}") args))  # the first parameter of map, a function that import and execute a nix file
  (builtins.filter          # the second parameter of map, a list of all nix files in the current folder except default.nix
    (f: f != "default.nix")
    (builtins.attrNames (builtins.readDir ./.)))
