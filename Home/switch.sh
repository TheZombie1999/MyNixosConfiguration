#!/usr/bin/env nix-shell
#! nix-shell -i bash -p coreutils ripgrep

set -euo pipefail

source ./Scripts/Colors/colors.include

function channelExistsOrAdd() {
  local channelName="${1}"
  shift
  local channelUrl="${1}"

  local channelEntry=$(nix-channel --list | awk '{print $1}' | rg $channelName)

  if [ -z "$channelEntry" ]; then
    echo "Adding Channel ${channelName}"
    nix-channel --add "$channelUrl" "$channelName"
  else
    echo "Channel $channelName Allready Exists "
  fi
}

function main() {
  local USER="$1"
  local MACHINEID="$2"
  local homeFileToInstall="./Users/${MACHINEID}-${USER}-home.nix"

  COLORMODE="${COLORMODE:-dark}"

  if ! [ -f "$homeFileToInstall" ]; then
    echo -e "$red ERROR: $clr File (${homeFileToInstall}) doesn't exist !!! $clr"
    exit 1
  fi

  echo -e "$grn Add Missing Nix Channels$clr"

  channelExistsOrAdd home-manager https://github.com/nix-community/home-manager/archive/master.tar.gz
  channelExistsOrAdd nix-colors https://github.com/misterio77/nix-colors/archive/main.tar.gz
  channelExistsOrAdd nixpkgs https://nixos.org/channels/nixpkgs-unstable
  channelExistsOrAdd nixpkgs-stable https://nixos.org/channels/nixos-23.11
  channelExistsOrAdd nixgl https://github.com/nix-community/nixGL/archive/main.tar.gz

  echo -e "$grn Update Nix Channels $clr"
  nix-channel --update

  echo -e "$grn Installing File ${homeFileToInstall} $clr"
  export NIXPKGS_ALLOW_UNFREE=1
  export NIXPKGS_ALLOW_INSECURE=1

  # home-manager switch -b backup --file "${homeFileToInstall}" -A "$COLORMODE"
  # home-manager switch -b backup --file "${homeFileToInstall}"
  home-manager switch -b backup --file "${homeFileToInstall}" -I "home-manager=${HOME}/home-manager" --show-trace

  # Create Stable Link for shfmt
  mkdir -p ~/.local/bin
  ln -sf "$(which shfmt)" ~/.local/bin/shfmt
}

main "$(whoami)" "$(cat /etc/machine-id)"
