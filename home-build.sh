#!/bin/sh
pushd ~/.dotfiles
nix build .#homeConfigurations.mykolas.activationPackage
./result/activate
popd
