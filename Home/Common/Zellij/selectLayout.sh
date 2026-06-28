#!/usr/bin/env nix-shell
#!nix-shell -i bash -p zellij findutils fzf

layout="$(find ~/.config/zellij/layouts -type l -o -type f | fzf)"

echo "${layout}"

zellij --layout "${layout}"
