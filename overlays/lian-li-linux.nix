# lian-li-linux (L-Connect 3 replacement for Lian Li devices — HydroShift LCD
# AIO fan/pump/RGB/LCD control + UNI FAN hubs). Self-contained vendored
# packaging in pkgs/lian-li-linux, adapted from SChimera/lian-li-linux-nix
# (MIT) for upstream v1.1.4 (npm frontend). Exposed as pkgs.lianli-linux,
# consumed by nixos/lianli.nix (myconf.nixos.lianli.enable).
final: _prev: {
  lianli-linux = final.callPackage ../pkgs/lian-li-linux/package.nix { };
}
