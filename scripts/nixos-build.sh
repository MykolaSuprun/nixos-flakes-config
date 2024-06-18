#!/usr/bin/env bash
set -e
cd ~/.nixconf
git diff -U0 *.nix 
# sudo nixos-rebuild switch --flake .#$NIXOS_TARGET --accept-flake-config
nh os switch -- --accept-flake-config
nix build .#homeConfigurations.$USER.activationPackage --accept-flake-config
./result/activate
gen=$(sudo nix-env -p /nix/var/nix/profiles/system --list-generations | grep current)
git commit -am "$gen"
cd -

