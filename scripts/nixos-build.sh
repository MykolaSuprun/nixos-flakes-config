#!/usr/bin/env bash
set -e
cd ~/.nixconf
git diff -U0 *.nix
gh os switch
sudo gen=$(nix-env -p /nix/var/nix/profiles/system --list-generations | grep current)
git commit -am "$gen"
cd -
