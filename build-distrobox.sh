#!/bin/sh
pushd ~/.dotfiles/home-scripts/distrobox-dockerfiles
docker build . -t mykolasuprun/distrobox-arch
distrobox create --image mykolasuprun/distrobox-arch --name arch
popd