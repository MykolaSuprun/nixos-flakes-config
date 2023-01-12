#!/bin/sh
pushd ~/.dotfiles
home-manager switch -f ./users/mykolas/home.nix
popd
