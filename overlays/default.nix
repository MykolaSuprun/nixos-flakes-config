# return the list of overlays in the directory
(
  with builtins; let
    excludedFiles = [
      "default.nix"
    ];
  in
    map (f: import (./. + "/${f}"))
    (filter (f: !(elem f excludedFiles)) (attrNames (readDir ./.)))
)
