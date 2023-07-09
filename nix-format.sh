#!/bin/sh
find . -name "*.nix" | xargs -L 1 -d '\n' nixfmt
