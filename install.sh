#!/bin/sh

# this installer can replace a lot of config files
# it backs them up before copying anything
# read the dry run first, unless you like gambling

set -eu

repo_owner=${DOTFILES_OWNER:-shredos67}
repo_name=${DOTFILES_REPO:-dotfiles}
repo_ref=${DOTFILES_REF:-main}
source_override=${DOTFILES_SOURCE_DIR:-}
assume_yes=${DOTFILES_YES:-0}
dry_run=0
install_packages=1
install_plugins=1
install_autologin=0
wallpaper=
work_root=
backup_root=

usage() {
    cat <<'EOF'
usage, install sh options

  --dry-run          show every change without writing it
  --yes              skip the confirmation
  --no-packages      do not install system packages or python tools
  --no-plugins       do not build the hyprland plugins
  --with-autologin   install the tty one autologin override
  --wallpaper path   seed pywal with this wallpaper
  --help             show this text
EOF
}

say() {
    printf '%s\n' "$*"
}

warn() {
    printf 'warning, %s\n' "$*" >&2
}

die() {
    printf 'error, %s\n' "$*" >&2
    exit 1
}

print_command() {
    printf '+'
    for word in "$@"; do
        printf ' %s' "$word"
    done
    printf '\n'
}

run() {
    if [ "$dry_run" -eq 1 ]; then
        print_command "$@"
        return 0
    fi
    "$@"
}

root_run() {
    if [ "$(id -u)" -eq 0 ]; then
        run "$@"
    elif command -v sudo >/dev/null 2>&1; then
        run sudo "$@"
    elif command -v doas >/dev/null 2>&1; then
        run doas "$@"
    else
        die "sudo or doas is needed for package and system changes"
    fi
}

cleanup() {
    if [ -n "$work_root" ] && [ -d "$work_root" ]; then
        rm -rf -- "$work_root"
    fi
}

while [ "$#" -gt 0 ]; do
    case $1 in
        --dry-run)
            dry_run=1
            ;;
        --yes)
            assume_yes=1
            ;;
        --no-packages)
            install_packages=0
            ;;
        --no-plugins)
            install_plugins=0
            ;;
        --with-autologin)
            install_autologin=1
            ;;
        --wallpaper)
            [ "$#" -ge 2 ] || die "wallpaper needs a path"
            wallpaper=$2
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            die "unknown option $1"
            ;;
    esac
    shift
done

if [ "$dry_run" -eq 0 ] && [ "$assume_yes" -ne 1 ]; then
    if [ -r /dev/tty ]; then
        printf 'this will back up and replace the managed dotfiles, continue, y or n  ' >/dev/tty
        IFS= read -r answer </dev/tty
        case $answer in
            y|Y|yes|YES) ;;
            *) exit 0 ;;
        esac
    else
        die "use the yes option when running without a terminal"
    fi
fi

work_root=$(mktemp -d "${TMPDIR:-/tmp}/shredos-dotfiles.XXXXXX")
trap cleanup EXIT HUP INT TERM

if [ -n "$source_override" ]; then
    source_dir=$(cd "$source_override" && pwd)
else
    command -v curl >/dev/null 2>&1 || die "curl is required"
    command -v tar >/dev/null 2>&1 || die "tar is required"
    archive="$work_root/dotfiles.tar.gz"
    archive_url="https://github.com/$repo_owner/$repo_name/archive/refs/heads/$repo_ref.tar.gz"
    say "downloading $repo_owner slash $repo_name"
    curl -fsSL "$archive_url" -o "$archive"
    mkdir -p "$work_root/download"
    tar -xzf "$archive" -C "$work_root/download"
    source_dir=$(find "$work_root/download" -mindepth 1 -maxdepth 1 -type d | head -n 1)
fi

[ -f "$source_dir/install.sh" ] || die "the downloaded repo is missing install sh"
[ -d "$source_dir/home" ] || die "the downloaded repo is missing the home tree"

install_system_packages() {
    [ "$install_packages" -eq 1 ] || return 0

    if command -v dnf >/dev/null 2>&1; then
        root_run dnf install -y dnf-plugins-core || \
            warn "dnf plugins could not be installed"
        root_run dnf copr enable -y lionheartp/Hyprland || \
            warn "the hyprland copr could not be enabled"
        root_run dnf install -y --skip-unavailable \
            hyprland hyprlock quickshell awww foot fastfetch neovim cava bluez NetworkManager \
            grim slurp imv brightnessctl playerctl jq ImageMagick \
            nautilus nwg-look qt5ct qt6ct obs-studio \
            python3-pip rsync curl git tar unzip util-linux libnotify || \
            warn "some fedora packages could not be installed"
    elif command -v pacman >/dev/null 2>&1; then
        root_run pacman -S --needed --noconfirm \
            hyprland hyprlock quickshell awww foot fastfetch neovim cava bluez bluez-utils networkmanager \
            grim slurp imv brightnessctl playerctl jq imagemagick \
            nautilus nwg-look qt5ct qt6ct obs-studio \
            python-pip rsync curl git tar unzip util-linux libnotify || \
            warn "some arch packages could not be installed"
    elif command -v apt-get >/dev/null 2>&1; then
        root_run apt-get update || warn "apt metadata could not be refreshed"
        root_run apt-get install -y \
            foot fastfetch neovim cava bluez network-manager grim slurp imv brightnessctl playerctl \
            jq imagemagick nautilus qt5ct qt6ct obs-studio \
            python3-pip rsync curl git tar unzip util-linux libnotify-bin || \
            warn "some debian packages could not be installed"
        warn "hyprland quickshell awww and hyprlock may need third party packages on this distro"
    else
        warn "no supported package manager was found"
    fi

    if ! command -v wal >/dev/null 2>&1 || ! command -v pywalfox >/dev/null 2>&1; then
        if command -v python3 >/dev/null 2>&1; then
            run python3 -m pip install --user --break-system-packages pywal16 pywalfox || \
                warn "pywal or pywalfox could not be installed"
        else
            warn "python is missing, pywal and pywalfox were skipped"
        fi
    fi
}

install_gomono_font() {
    if command -v fc-match >/dev/null 2>&1 && \
       fc-match 'Go Mono Nerd Font Mono' 2>/dev/null | grep -qi 'go.*mono'; then
        return 0
    fi

    [ "$install_packages" -eq 1 ] || {
        warn "go mono nerd font is missing"
        return 0
    }

    command -v curl >/dev/null 2>&1 || return 0
    command -v unzip >/dev/null 2>&1 || return 0

    font_archive="$work_root/go-mono.zip"
    font_dir="$HOME/.local/share/fonts/GoMono-Nerd"
    run mkdir -p "$font_dir"
    if [ "$dry_run" -eq 1 ]; then
        print_command curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Go-Mono.zip -o "$font_archive"
        print_command unzip -oq "$font_archive" -d "$font_dir"
    else
        curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Go-Mono.zip -o "$font_archive" || {
            warn "go mono nerd font could not be downloaded"
            return 0
        }
        unzip -oq "$font_archive" -d "$font_dir"
        command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true
    fi
}

install_system_packages
install_gomono_font

if command -v fc-match >/dev/null 2>&1 && \
   ! fc-match 'PP Right Serif Mono' 2>/dev/null | grep -qi 'right.*serif'; then
    warn "pp right serif mono is not included, install your licensed copy for the intended look"
fi

stage_home="$work_root/stage/home"
mkdir -p "$stage_home"
cp -a "$source_dir/home/." "$stage_home/"

escaped_home=$(printf '%s' "$HOME" | sed 's/[&|]/\\&/g')
escaped_user=$(id -un | sed 's/[&|]/\\&/g')
grep -Ilr -e '__HOME__' -e '__USER__' "$stage_home" 2>/dev/null | while IFS= read -r file; do
    sed -i \
        -e "s|__HOME__|$escaped_home|g" \
        -e "s|__USER__|$escaped_user|g" \
        "$file"
done

if [ "$(uname -m)" != aarch64 ]; then
    caelestia_found=0
    for qml_root in /usr/lib/qt6/qml /usr/lib64/qt6/qml /usr/local/lib/qt6/qml; do
        if [ -d "$qml_root/Caelestia" ]; then
            caelestia_found=1
            break
        fi
    done
    if [ "$caelestia_found" -eq 0 ]; then
        die "the bundled caelestia plugin is arm only, install caelestia shell for your cpu first"
    fi
    rm -rf -- "$stage_home/.config/quickshell/Caelestia"
fi

timestamp=$(date +%Y%m%d-%H%M%S)
backup_root="$HOME/.local/state/dotfiles-backups/$timestamp"

install_one() {
    relative=$1
    source_path="$stage_home/$relative"
    target_path="$HOME/$relative"
    backup_path="$backup_root/$relative"
    preserved_session_image=
    preserved_shell_settings=

    [ -e "$source_path" ] || [ -L "$source_path" ] || return 0

    if [ "$relative" = .config/quickshell ] && \
       [ -f "$target_path/session_img.png" ]; then
        preserved_session_image="$work_root/session_img.png"
        run cp -a "$target_path/session_img.png" "$preserved_session_image"
    fi

    if [ "$relative" = .config/quickshell ] && \
       [ -f "$target_path/floral-settings.json" ]; then
        preserved_shell_settings="$work_root/floral-settings.json"
        run cp -a "$target_path/floral-settings.json" "$preserved_shell_settings"
    fi

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        run mkdir -p "${backup_path%/*}"
        run mv "$target_path" "$backup_path"
    fi

    run mkdir -p "${target_path%/*}"
    run cp -a "$source_path" "$target_path"

    if [ -n "$preserved_session_image" ]; then
        run cp -a "$preserved_session_image" "$target_path/session_img.png"
    fi

    if [ -n "$preserved_shell_settings" ]; then
        run cp -a "$preserved_shell_settings" "$target_path/floral-settings.json"
    fi
}

managed_paths='
.config/quickshell
.config/hypr
.config/wal
.config/fastfetch
.config/foot
.config/nvim
.config/gtk-3.0/gtk.css
.config/gtk-3.0/settings.ini
.config/gtk-4.0/gtk.css
.config/gtk-4.0/settings.ini
.config/qt5ct
.config/qt6ct
.config/nwg-look
.config/dstl
.config/systemd/user/hyprland-session.target
.config/obs-studio/basic/profiles/Untitled
.config/obs-studio/basic/scenes/Untitled.json
.local/share/icons/Pywal
.local/share/applications/floral-shell-settings.desktop
.local/bin/dstl-launcher
.local/bin/quickshell-obs-record
.local/bin/quickshell-screenshot
.local/bin/reload-hypr-plugins-layered
.local/bin/update-fastfetch-theme
.local/bin/update-imgborders-theme
wallpaperCarousel
'

for relative in $managed_paths; do
    install_one "$relative"
done

install_firefox_css() {
    css_source="$source_dir/extras/firefox/userChrome.css"
    [ -f "$css_source" ] || return 0

    for firefox_root in "$HOME/.mozilla/firefox" "$HOME/.config/mozilla/firefox"; do
        [ -d "$firefox_root" ] || continue

        profile_name=
        if [ -f "$firefox_root/installs.ini" ]; then
            profile_name=$(sed -n 's/^Default=//p' "$firefox_root/installs.ini" | head -n 1)
        fi
        if [ -z "$profile_name" ] && [ -f "$firefox_root/profiles.ini" ]; then
            profile_name=$(sed -n 's/^Path=//p' "$firefox_root/profiles.ini" | head -n 1)
        fi
        [ -n "$profile_name" ] || continue

        case $profile_name in
            /*) profile_dir=$profile_name ;;
            *) profile_dir="$firefox_root/$profile_name" ;;
        esac

        [ -d "$profile_dir" ] || continue
        chrome_dir="$profile_dir/chrome"
        css_target="$chrome_dir/userChrome.css"

        if [ -f "$css_target" ]; then
            run mkdir -p "$backup_root/firefox"
            run cp -a "$css_target" "$backup_root/firefox/userChrome.css"
        fi
        run mkdir -p "$chrome_dir"
        run cp -a "$css_source" "$css_target"

        user_js="$profile_dir/user.js"
        pref_line='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
        if ! grep -Fq "$pref_line" "$user_js" 2>/dev/null; then
            if [ "$dry_run" -eq 1 ]; then
                say "+ add the firefox chrome preference to $user_js"
            else
                printf '%s\n' "$pref_line" >> "$user_js"
            fi
        fi
        return 0
    done

    warn "no firefox profile was found, the font css is in extras slash firefox"
}

install_firefox_css

if [ "$install_autologin" -eq 1 ]; then
    override_source="$stage_home/.config/hypr/getty-tty1-autologin.conf"
    override_target=/etc/systemd/system/getty@tty1.service.d/override.conf
    root_run mkdir -p /etc/systemd/system/getty@tty1.service.d
    if [ -f "$override_target" ]; then
        root_run cp -a "$override_target" "$override_target.backup.$timestamp"
    fi
    root_run install -m 0644 "$override_source" "$override_target"
fi

install_hypr_plugins() {
    [ "$install_plugins" -eq 1 ] || return 0
    command -v hyprpm >/dev/null 2>&1 || {
        warn "hyprpm is missing, window border plugins were skipped"
        return 0
    }

    plugin_list=$(hyprpm list 2>/dev/null || true)
    if ! printf '%s' "$plugin_list" | grep -q 'Repository hyprland-plugins'; then
        run hyprpm add https://github.com/hyprwm/hyprland-plugins || \
            warn "borders plus plus could not be built"
    fi
    if ! printf '%s' "$plugin_list" | grep -q 'Repository imgborders'; then
        run hyprpm add https://codeberg.org/zacoons/imgborders || \
            warn "image borders could not be built"
    fi
    run hyprpm enable borders-plus-plus || warn "borders plus plus could not be enabled"
    run hyprpm enable imgborders || warn "image borders could not be enabled"
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        run hyprpm reload || warn "hyprland plugins will load after the next login"
    fi
}

install_hypr_plugins

seed_theme() {
    command -v wal >/dev/null 2>&1 || {
        warn "wal is missing, the fallback colors will stay active"
        return 0
    }

    if [ -n "$wallpaper" ]; then
        seed_wallpaper=$wallpaper
    else
        seed_wallpaper="$HOME/.config/quickshell/assets/wallpaper.webp"
    fi
    [ -f "$seed_wallpaper" ] || {
        warn "the seed wallpaper does not exist"
        return 0
    }

    if [ "$dry_run" -eq 1 ]; then
        print_command wal -i "$seed_wallpaper" -n -q -s -e
        return 0
    fi

    wal -i "$seed_wallpaper" -n -q -s -e
    wal_cache="${XDG_CACHE_HOME:-$HOME/.cache}/wal"

    for pair in \
        "wal-colors.lua:$HOME/.config/hypr/wal-colors.lua" \
        "hyprlock.conf:$HOME/.config/hypr/hyprlock.conf" \
        "gtk3.css:$HOME/.config/gtk-3.0/gtk.css" \
        "gtk4.css:$HOME/.config/gtk-4.0/gtk.css" \
        "qtct-pywal.conf:$HOME/.config/qt5ct/colors/pywal.conf" \
        "qtct-pywal.conf:$HOME/.config/qt6ct/colors/pywal.conf"
    do
        generated_name=${pair%%:*}
        generated_target=${pair#*:}
        if [ -f "$wal_cache/$generated_name" ]; then
            mkdir -p "${generated_target%/*}"
            install -m 0644 "$wal_cache/$generated_name" "$generated_target"
        fi
    done

    command -v magick >/dev/null 2>&1 && \
        "$HOME/.local/bin/update-imgborders-theme" || true
    command -v jq >/dev/null 2>&1 && \
        "$HOME/.local/bin/update-fastfetch-theme" || true
}

seed_theme

if command -v pywalfox >/dev/null 2>&1; then
    run pywalfox install >/dev/null 2>&1 || warn "pywalfox native messaging was not installed"
fi

if command -v systemctl >/dev/null 2>&1; then
    run systemctl --user daemon-reload || true
fi

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
    run hyprctl reload config-only || warn "hyprland will load the config after the next login"
fi

say "done, backups are in $backup_root"
say "add wallpapers to $HOME slash Wallpapers"
say "add your own face file and quickshell session image if you want them"
say "log out and back in when you are ready"
