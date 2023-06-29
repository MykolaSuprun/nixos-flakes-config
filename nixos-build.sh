#!/bin/sh
pushd ~/.dotfiles
sudo nixos-rebuild switch --flake .#Geks-Nixos
popd
