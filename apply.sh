#!/bin/sh
pushd ~/.dotfiles
./apply-system.sh
./apply-users.sh
popd
