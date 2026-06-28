#!/usr/bin/env bash

if ! [ -z "$zellij" ] ;then
  echo "Not in zellij !"
  exit 0 
fi

action="$(zellij action list-panes -a -j)"

echo -e "${action}"

mapfile -t listpanes < <(echo "${action}" | jq 'map(select(.is_plugin | not) | select(.title | test("Editing") )) | unique | .[].id')
mapfile -t listterminal < <(echo "${action}" | jq 'map(select(.is_plugin | not) | select(.title | test("Pane") )) | unique | .[].id')
mapfile -t listrun < <(echo "${action}" | jq 'map(select(.terminal_command != null )) | unique | .[].id')

if ! [[ ${#listpanes[@]} -eq 0 ]]; then
  echo "${listpanes[@]}"
  zellij action stack-panes -- ${listpanes[@]}
fi

if ! [[ ${#listterminal[@]} -eq 0 ]]; then
  echo "${listterminal[@]}"
  zellij action stack-panes -- ${listterminal[@]}
fi

if ! [[ ${#listrun[@]} -eq 0 ]]; then
  echo "${listrun[@]}"
  zellij action stack-panes -- ${listrun[@]}
fi
