#!/usr/bin/bash

layout="$(find ~/.config/zellij/layouts -type l -o -type f | fzf)"

echo "${layout}"

zellij --layout "${layout}"
# zellij action close-pane
