#!/bin/sh
pushd ~/.dotfiles
nix build .#homeConfigurations.${home_manager_target}.activationPackage
./result/activate
popd
