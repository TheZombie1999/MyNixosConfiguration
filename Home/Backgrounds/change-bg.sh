#!/usr/bin/env nix-shell
#!nix-shell -i bash
#!nix-shell -p bash coreutils gnused gawk findutils gsettings-desktop-schemas dbus libnotify
#!nix-shell -p wmctrl xprop feh swaybg xfconf
#!nix-shell -p gnome-shell
#!nix-shell -p kdePackages.qttools

set -eEu

# Usage: ./set-wallpaper.sh /path/to/image.jpg [fill|fit|stretch|tile|center]
# Default mode: fill

IMAGE="$1"
MODE="${2:-fill}"

if [[ -z "$IMAGE" || ! -f "$IMAGE" ]]; then
    echo "Error: Provide a valid image path as first argument."
    echo "Usage: $0 /path/to/image.jpg [fill|fit|stretch|tile|center]"
    exit 1
fi

# Convert to absolute path (required for most tools)
IMAGE="$(realpath "$IMAGE")"

# Detect session type
SESSION_TYPE="${XDG_SESSION_TYPE,,}"  # wayland or x11 (lowercase)

# Detect desktop environment
DESKTOP="${XDG_CURRENT_DESKTOP,,}"    # e.g. gnome, kde, sway, xfce

echo "Detected session: $SESSION_TYPE"
echo "Detected desktop: $DESKTOP"
echo "Setting wallpaper: $IMAGE (mode: $MODE)"

set_wallpaper() {
    case "$1" in
        gnome|ubuntu:gnome)
            gsettings set org.gnome.desktop.background picture-uri "file://$IMAGE"
            gsettings set org.gnome.desktop.background picture-uri-dark "file://$IMAGE"
            case "$MODE" in
                fill)     opts='zoom' ;;
                fit)      opts='scaled' ;;
                stretch)  opts='stretched' ;;
                center)   opts='centered' ;;
                tile)     opts='wallpaper' ;;
                *)        opts='zoom' ;;
            esac
            gsettings set org.gnome.desktop.background picture-options "$opts"
            ;;
        kde|plasma)
            # Works on both X11 and Wayland Plasma
            qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
                var Desktops = desktops();
                for (i=0; i<Desktops.length; i++) {
                    d = Desktops[i];
                    d.wallpaperPlugin = 'org.kde.image';
                    d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
                    d.writeConfig('Image', 'file://$IMAGE');
                }"
            ;;
        xfce|xfce4)
            xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$IMAGE"
            # For multi-monitor setups you may need to adjust per monitor property
            ;;
        cinnamon)
            gsettings set org.cinnamon.desktop.background picture-uri "file://$IMAGE"
            gsettings set org.cinnamon.desktop.background picture-options "$MODE"
            ;;
        sway|hyprland|river|wayfire|labwc)
            # wlroots-based compositors – use swaybg (works for most)
            pkill swaybg 2>/dev/null
            swaybg -i "$IMAGE" -m "$MODE" &
            ;;
        *)
            # Fallback based on session type
            if [[ "$SESSION_TYPE" == "x11" ]]; then
                if command -v feh >/dev/null; then
                    feh --bg-"$MODE" "$IMAGE"
                    echo "Fallback: Used feh (X11)"
                else
                    echo "Error: No supported WM/DE detected and feh not installed."
                    exit 1
                fi
            elif [[ "$SESSION_TYPE" == "wayland" ]]; then
                if command -v swaybg >/dev/null; then
                    pkill swaybg 2>/dev/null
                    swaybg -i "$IMAGE" -m "$MODE" &
                    echo "Fallback: Used swaybg (Wayland)"
                else
                    echo "Error: No supported compositor detected and swaybg not installed."
                    exit 1
                fi
            else
                echo "Error: Could not detect session type."
                exit 1
            fi
            ;;
    esac
}

# Main detection logic
case "$DESKTOP" in
    *gnome*)          set_wallpaper gnome ;;
    *kde*|*plasma*)   set_wallpaper kde ;;
    *xfce*)           set_wallpaper xfce ;;
    *cinnamon*)       set_wallpaper cinnamon ;;
    sway|hyprland)    set_wallpaper sway ;;  # Hyprland also matches swaybg
    *)
        # Additional check for running processes if DE is ambiguous
        if pgrep -x "mutter" >/dev/null; then
            set_wallpaper gnome
        elif pgrep -x "kwin_" >/dev/null; then
            set_wallpaper kde
        elif pgrep -f "sway|hypr|wayfire|river" >/dev/null; then
            set_wallpaper sway
        else
            set_wallpaper fallback
        fi
        ;;
esac

echo "Wallpaper set successfully!"
