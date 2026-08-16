pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    property string wallpaperDirectory: `${Quickshell.env("HOME")}/Wallpapers`
    property string currentWallpaper: ""
    readonly property bool active: carousel.active

    readonly property string pywalStatePath: (Quickshell.env("XDG_CACHE_HOME") || `${Quickshell.env("HOME")}/.cache`) + "/wal/colors.json"
    readonly property string applyScript: `${Quickshell.env("HOME")}/wallpaperCarousel/apply-wallpaper.sh`

    function focusedScreen() {
        const monitorName = Hyprland.focusedMonitor?.name ?? "";
        for (const screen of Quickshell.screens) {
            if (screen.name === monitorName)
                return screen;
        }

        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function applyWallpaper(path) {
        if (!path)
            return;

        root.currentWallpaper = path;
        Quickshell.execDetached([root.applyScript, path]);
    }

    function open() {
        carousel.open();
    }

    function close() {
        carousel.close();
    }

    function toggle() {
        carousel.toggle();
    }

    Carousel {
        id: carousel

        anchors.fill: parent
        wlrNamespace: "wallpaper-carousel"
        defaultWallpaperFolder: root.wallpaperDirectory
        currentWallpaperPath: root.currentWallpaper
        getFocusedScreen: root.focusedScreen
        hasWallpaperConfigured: root.wallpaperDirectory.length > 0
        shellSettingsHint: `Put wallpapers in ${root.wallpaperDirectory}`

        cfg: ({
            "wallpaperDirectory": root.wallpaperDirectory,
            "carouselMode": "wrap",
            "overlayOpacity": 80,
            "cornerRadius": 0,
            "itemWidth": 400,
            "itemHeight": 420,
            "borderWidth": 3,
            "spacing": 10,
            "selectedScale": 108,
            "expandMultiplier": 120,
            "enableHoldExpand": "false",
            "holdExpandRatio": 35,
            "holdDelay": 1500,
            "cacheSize": 24
        })

        onWallpaperPicked: (fullPath, screenName) => root.applyWallpaper(fullPath)
    }

    FileView {
        path: root.pywalStatePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const state = JSON.parse(text());
                if (state.wallpaper)
                    root.currentWallpaper = state.wallpaper;
            } catch (error) {
                console.warn(`WallpaperCarousel: could not read Pywal state: ${error}`);
            }
        }
    }
}
