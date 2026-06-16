
set -x

zellij_first_client() {
    # Get output, skip header, take only first real line
    zellij action list-clients 2>/dev/null | 
        awk 'NR==2 {
            id = $1
            pane = $2
            # Get the rest of the line (command) as-is
            cmd = substr($0, index($0,$3))
            print id, pane, cmd
            exit
        }'
}

if ! [ -z "$zellij" ] ;then
  echo "Not in zellij !"
  exit 0 
fi

editors=()
checkedpanes=()

for _ in {1..10} ; do
  zellij action list-clients
  read -r a b c <<< "$(zellij_first_client)"
  if [[ ${checkedpanes[*]} =~ $b ]] ; then
    break
  fi

  checkedpanes+=("$b")

  if ! (echo "${c}" | grep -Eq "yazi") ; then
    editors+=("${b}")
  fi
  zellij action focus-next-pane
done

if ! [[ ${#editors[@]} -eq 0 ]]; then
  timeout 4s zellij action stack-panes -- ${editors[@]}
  exit 0
fi
