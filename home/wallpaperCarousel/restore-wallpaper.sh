#!/bin/sh

# this script brings back the last wallpaper
# it can start awww when needed
# keep it quiet during login

set -eu

state_home=${XDG_STATE_HOME:-"$HOME/.local/state"}
cache_home=${XDG_CACHE_HOME:-"$HOME/.cache"}
saved_path="$state_home/wallpaperCarousel/current"
pywal_state="$cache_home/wal/colors.json"
wallpaper=

mkdir -p "${saved_path%/*}"

if [ -s "$saved_path" ]; then
    IFS= read -r wallpaper < "$saved_path" || wallpaper=
fi

if [ -z "$wallpaper" ] && [ -s "$pywal_state" ]; then
    wallpaper=$(sed -n 's/^[[:space:]]*"wallpaper":[[:space:]]*"\(.*\)",[[:space:]]*$/\1/p' "$pywal_state" | head -n 1)
fi

if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
    exit 0
fi

attempts=0
while ! awww query >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if [ "$attempts" -eq 10 ]; then
        setsid -f awww-daemon </dev/null >/dev/null 2>&1
    fi
    if [ "$attempts" -ge 100 ]; then
        echo "Timed out waiting for awww-daemon" >&2
        exit 1
    fi
    sleep 0.1
done

awww img "$wallpaper" --transition-type none
printf '%s\n' "$wallpaper" > "$saved_path"
