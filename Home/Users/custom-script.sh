#!/bin/bash

WALLPAPER="$(find "${HOME}/Bilder/Backgrounds/" -type f | sort -R | head -n 1)"

case $XDG_CURRENT_DESKTOP in
GNOME)
  gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER"
  ;;
KDE)
  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var allDesktops = desktops();
for (i=0; i<allDesktops.length; i++) {
  d = allDesktops[i];
  d.wallpaperPlugin = 'org.kde.image';
  d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
  d.writeConfig('Image', 'file://$WALLPAPER');
}
"
  ;;
XFCE)
  xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$WALLPAPER"
  ;;
LXQt)
  pcmanfm-qt --set-wallpaper="$WALLPAPER"
  ;;
MATE)
  gsettings set org.mate.desktop.background picture-filename "$WALLPAPER"
  ;;
Cinnamon)
  gsettings set org.cinnamon.desktop.background picture-uri "file://$WALLPAPER"
  ;;
*)
  # Fallback to feh if available
  if command -v feh >/dev/null; then
    feh --bg-scale "$WALLPAPER"
  fi
  ;;
esac
