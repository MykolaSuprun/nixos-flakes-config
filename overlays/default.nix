# return the list of overlays in the directory
(
  with builtins;
    map (f: import (./. + "/${f}"))
    (filter (f: f != "default.nix") (attrNames (readDir ./.)))
)
