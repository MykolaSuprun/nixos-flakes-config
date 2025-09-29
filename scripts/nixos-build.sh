#!/usr/bin/env bash
set -e
cd "$NIXOS_CONF_DIR"
git diff -U0 *.nix
nh os switch -- \
  --accept-flake-config --show-trace \
  --option extra-substituters https://install.determinate.systems \
  --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=
gen=$(sudo nix-env -p /nix/var/nix/profiles/system --list-generations | grep current)
git commit -am "$gen"
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE+set}" ]; then
  hyprctl reload && pypr reload
fi
cd -
