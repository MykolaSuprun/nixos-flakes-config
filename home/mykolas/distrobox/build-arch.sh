#!/bin/sh
pushd ~/.dotfiles/home/mykolas/distrobox/dockerfiles/archlinux
docker build . -t mykolasuprun/distrobox-arch
docker rmi $(docker images -qa -f 'dangling=true')
distrobox create --image mykolasuprun/distrobox-arch --name arch
popd
