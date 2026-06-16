

function zellij_active(){
  echo "Zellij"

  # Use Zelij edit
  zellij edit "$1"
}

function normal_mode(){
  echo "Normal"

  # Spawn New Terminal With editor
  alacritty -e hx "$1" 
}

if [ -n "$ZELLIJ" ] ;then
  zellij_active "$@"
else
  normal_mode "$@"
fi


