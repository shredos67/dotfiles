#!/bin/sh

# this script starts one wallpaper change
# change the values below for awww timing
# the theme changes before the wallpaper

set -eu

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/wallpaper" >&2
    exit 2
fi

wallpaper=$(realpath "$1")
if [ ! -f "$wallpaper" ]; then
    echo "Wallpaper does not exist: $wallpaper" >&2
    exit 1
fi

state_home=${XDG_STATE_HOME:-"$HOME/.local/state"}
state_dir="$state_home/wallpaperCarousel"

transition_type=${AWWW_TRANSITION_TYPE:-grow}
transition_duration=${AWWW_TRANSITION_DURATION:-0.8}
transition_fps=${AWWW_TRANSITION_FPS:-60}
color_settle_delay=${AWWW_COLOR_SETTLE_DELAY:-0.0}
theme_worker="$HOME/wallpaperCarousel/sync-wallpaper-theme.sh"

mkdir -p "$state_dir"
printf '%s\n' "$wallpaper" > "$state_dir/theme-pending"

setsid -f "$theme_worker" \
    "$transition_type" "$transition_duration" "$transition_fps" "$color_settle_delay" \
    </dev/null >/dev/null 2>&1
