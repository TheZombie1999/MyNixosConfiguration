#!/usr/bin/env bash
export NIXPKGS_ALLOW_UNFREE=1


# sudo nixos-rebuild switch --upgrade -I nixos-config=./Maschines/lenovo.nix 
# sudo nixos-rebuild switch --upgrade -I nixos-config=./Maschines/wsl.nix 
echo 65787465 | sudo -S nixos-rebuild switch --upgrade -I nixos-config=./Maschines/microstar.nix 
