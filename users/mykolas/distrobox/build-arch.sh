#!/bin/sh
pushd ~/.dotfiles/users/mykolas/distrobox/dockerfiles/archlinux
docker build . -t mykolasuprun/distrobox-arch
distrobox create --image mykolasuprun/distrobox-arch --name arch
popd