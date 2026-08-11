#!/bin/sh

# this script changes the whole theme
# it builds everything first, then swaps the files
# do not split the order unless you know why

set -eu

transition_type=${1:-grow}
transition_duration=${2:-1.8}
transition_fps=${3:-45}
color_settle_delay=${4:-0.2}

state_home=${XDG_STATE_HOME:-"$HOME/.local/state"}
state_dir="$state_home/wallpaperCarousel"
cache_home=${XDG_CACHE_HOME:-"$HOME/.cache"}
wal_cache="$cache_home/wal"
pending_file="$state_dir/theme-pending"
applied_file="$state_dir/theme-applied"
current_file="$state_dir/current"
stage_dir=

mkdir -p "$state_dir"

exec 9>"$state_dir/theme.lock"
flock 9

cleanup_stage() {
    if [ -n "$stage_dir" ] && [ -d "$stage_dir" ]; then
        rm -rf -- "$stage_dir"
    fi
}
trap cleanup_stage EXIT HUP INT TERM

read_path() {
    path_file=$1
    read_value=
    if [ -s "$path_file" ]; then
        IFS= read -r read_value < "$path_file" || read_value=
    fi
    printf '%s' "$read_value"
}

write_path() {
    write_value=$1
    write_target=$2
    write_tmp="$write_target.tmp.$$"
    printf '%s\n' "$write_value" > "$write_tmp"
    mv -f "$write_tmp" "$write_target"
}

run_idle() {
    if command -v ionice >/dev/null 2>&1; then
        ionice -c 3 nice -n 10 "$@"
    else
        nice -n 10 "$@"
    fi
}

ensure_awww() {
    if ! awww query >/dev/null 2>&1; then
        setsid -f awww-daemon </dev/null >/dev/null 2>&1
    fi

    attempts=0
    while ! awww query >/dev/null 2>&1; do
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 100 ]; then
            echo "Timed out waiting for awww-daemon" >&2
            return 1
        fi
        sleep 0.1
    done
}

prepare_folder_icons() {
    stage_wal=$1
    stage_icon_theme=$2
    stage_signature_file=$3

    [ -f "$stage_wal/folder-colors.sh" ] || return 0

    . "$stage_wal/folder-colors.sh"

    icon_signature="$folder_back:$folder_base:$folder_front:$folder_shine:$folder_edge"
    printf '%s\n' "$icon_signature" > "$stage_signature_file"

    live_icon_theme="$HOME/.local/share/icons/Pywal"
    live_signature_file="$state_dir/folder-colors"
    if [ "$(read_path "$live_signature_file")" = "$icon_signature" ] &&
       [ -f "$live_icon_theme/icon-theme.cache" ]; then
        return 0
    fi

    icon_source=/usr/share/icons/Adwaita/scalable/places
    stage_icon_target="$stage_icon_theme/scalable/places"
    mkdir -p "$stage_icon_target"
    install -m 0644 "$live_icon_theme/index.theme" "$stage_icon_theme/index.theme"

    for source_icon in "$icon_source"/folder*.svg; do
        [ -f "$source_icon" ] || continue
        target_icon="$stage_icon_target/${source_icon##*/}"
        run_idle sed \
            -e "s|#438de6|$folder_back|g" \
            -e "s|#62a0ea|$folder_base|g" \
            -e "s|#a4caee|$folder_front|g" \
            -e "s|#afd4ff|$folder_shine|g" \
            -e "s|#c0d5ea|$folder_edge|g" \
            "$source_icon" > "$target_icon"
    done

    run_idle gtk-update-icon-cache -q -f "$stage_icon_theme" || true
}

prepare_theme() {
    wallpaper=$1

    stage_dir=$(mktemp -d "$state_dir/theme-stage.XXXXXX")
    stage_wal="$stage_dir/wal"
    stage_assets="$stage_dir/assets"
    stage_fastfetch="$stage_dir/fastfetch"
    stage_icon_theme="$stage_dir/icons/Pywal"
    mkdir -p "$stage_wal" "$stage_assets" "$stage_fastfetch"

    run_idle wal -i "$wallpaper" -n -q -s -e --out-dir "$stage_wal"

    run_idle env \
        IMGBORDERS_PALETTE="$stage_wal/colors.json" \
        IMGBORDERS_OUTPUT="$stage_assets/imgborders-floral.png" \
        IMGBORDERS_LOCK_OUTPUT="$stage_assets/imgborders-floral-lock-wide.png" \
        "$HOME/.local/bin/update-imgborders-theme"

    run_idle env \
        FASTFETCH_WAL_COLORS="$stage_wal/colors.json" \
        FASTFETCH_ART_OUTPUT="$stage_fastfetch/L_ascii.txt" \
        FASTFETCH_SEQUENCE_OUTPUT="$stage_fastfetch/fastfetch-sequences" \
        FASTFETCH_SEND_TERMINALS=0 \
        "$HOME/.local/bin/update-fastfetch-theme"

    prepare_folder_icons \
        "$stage_wal" "$stage_icon_theme" "$stage_dir/folder-colors"
}

install_generated_file() {
    source_file=$1
    target_file=$2
    [ -f "$source_file" ] || return 0
    install -C -m 0644 "$source_file" "$target_file"
}

send_terminal_colors() {
    for terminal_device in /dev/pts/[0-9]*; do
        [ -w "$terminal_device" ] || continue
        cat "$wal_cache/sequences" "$wal_cache/fastfetch-sequences" \
            > "$terminal_device" 2>/dev/null || true
    done
}

publish_theme() {
    stage_wal="$stage_dir/wal"
    stage_assets="$stage_dir/assets"
    stage_fastfetch="$stage_dir/fastfetch"
    stage_icon_theme="$stage_dir/icons/Pywal"
    live_icon_theme="$HOME/.local/share/icons/Pywal"

    mkdir -p "$wal_cache"
    cp -a "$stage_wal/." "$wal_cache/"

    install_generated_file "$stage_assets/imgborders-floral.png" \
        "$HOME/.config/hypr/assets/imgborders-floral.png"
    install_generated_file "$stage_assets/imgborders-floral-lock-wide.png" \
        "$HOME/.config/hypr/assets/imgborders-floral-lock-wide.png"
    install_generated_file "$stage_fastfetch/L_ascii.txt" \
        "$HOME/.config/fastfetch/L_ascii.txt"
    install_generated_file "$stage_fastfetch/fastfetch-sequences" \
        "$wal_cache/fastfetch-sequences"

    install_generated_file "$stage_wal/wal-colors.lua" \
        "$HOME/.config/hypr/wal-colors.lua"
    install_generated_file "$stage_wal/hyprlock.conf" \
        "$HOME/.config/hypr/hyprlock.conf"
    install_generated_file "$stage_wal/gtk3.css" \
        "$HOME/.config/gtk-3.0/gtk.css"
    install_generated_file "$stage_wal/gtk4.css" \
        "$HOME/.config/gtk-4.0/gtk.css"
    install_generated_file "$stage_wal/qtct-pywal.conf" \
        "$HOME/.config/qt5ct/colors/pywal.conf"
    install_generated_file "$stage_wal/qtct-pywal.conf" \
        "$HOME/.config/qt6ct/colors/pywal.conf"

    if [ -d "$stage_icon_theme/scalable" ]; then
        mkdir -p "$live_icon_theme"
        cp -a "$stage_icon_theme/." "$live_icon_theme/"
    fi

    write_path "$(read_path "$stage_dir/folder-colors")" \
        "$state_dir/folder-colors"

    send_terminal_colors

    hyprctl reload config-only >/dev/null 2>&1 &
    pywalfox update >/dev/null 2>&1 &
    if pgrep -x nautilus >/dev/null 2>&1; then
        nautilus -q >/dev/null 2>&1 &
    fi
    wait || true
}

while :; do
    requested=$(read_path "$pending_file")
    applied=$(read_path "$applied_file")

    [ -n "$requested" ] || exit 0
    [ -f "$requested" ] || exit 0
    [ "$requested" != "$applied" ] || exit 0

    prepare_theme "$requested"

    if [ "$(read_path "$pending_file")" != "$requested" ]; then
        cleanup_stage
        stage_dir=
        continue
    fi

    publish_theme
    write_path "$requested" "$applied_file"
    sleep "$color_settle_delay"

    ensure_awww
    awww img "$requested" \
        --transition-type "$transition_type" \
        --transition-pos center \
        --transition-duration "$transition_duration" \
        --transition-fps "$transition_fps"
    write_path "$requested" "$current_file"

    sleep "$transition_duration"

    cleanup_stage
    stage_dir=

    [ "$(read_path "$pending_file")" != "$requested" ] || exit 0
done
