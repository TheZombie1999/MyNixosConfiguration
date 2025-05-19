#!/usr/bin/env nix-shell
#! nix-shell -i bash -p coreutils ripgrep

set -euo pipefail

source ./Scripts/Colors/colors.include

# SCRIPT_PATH="$(realpath "$0")"
# # cat $SCRIPT_PATH

# trap error ERR

# error (){
#   local error_code=$?
#   local error_line=$BASH_LINENO
#   local error_command=$BASH_COMMAND

#   sed "$(($error_line-10)),$(($error_line-1))p;d" $SCRIPT_PATH
#   echo -ne "$red"
#   sed "$(($error_line))p;d" $SCRIPT_PATH
#   echo -ne "$clr"
#   sed "$(($error_line+1)),$(($error_line+10))p;d" $SCRIPT_PATH
# }

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
  local HOST="$2"
  local homeFileToInstall="./Users/${USER}-${HOST}-home.nix"

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
  # home-manager switch -b backup --file "${homeFileToInstall}" -A "$COLORMODE"
  home-manager switch -b backup --file "${homeFileToInstall}"
}

main "$(whoami)" "$(hostname)"
