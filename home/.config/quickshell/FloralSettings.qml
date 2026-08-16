pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias dockEnabled: saved.dockEnabled
    property alias dockAutoHide: saved.dockAutoHide
    property alias dockMagnification: saved.dockMagnification
    property alias dockTray: saved.dockTray
    property alias shadows: saved.shadows
    property alias ornaments: saved.ornaments
    property alias translucent: saved.translucent
    property alias motionEnabled: saved.motionEnabled
    property alias animationScale: saved.animationScale
    property alias iconSize: saved.iconSize
    property alias dockMargin: saved.dockMargin
    property alias interfaceScale: saved.interfaceScale
    property alias popupRadius: saved.popupRadius
    property alias barHeight: saved.barHeight
    property alias drawerRadius: saved.drawerRadius
    property alias accentStyle: saved.accentStyle
    property alias pinnedIds: saved.pinnedIds
    property alias idleEnabled: saved.idleEnabled
    property alias idleLockTimeoutMinutes: saved.idleLockTimeoutMinutes
    property alias idleDpmsTimeoutMinutes: saved.idleDpmsTimeoutMinutes
    property alias idleInhibitLockWhenPlaying: saved.idleInhibitLockWhenPlaying
    property alias idleInhibitDpmsWhenPlaying: saved.idleInhibitDpmsWhenPlaying
    property alias idleInhibitWhenCharging: saved.idleInhibitWhenCharging
    property alias idleLockBeforeSleep: saved.idleLockBeforeSleep

    property bool settingsOpen: false
    property bool dockLauncherOpen: false

    readonly property color accentColor: accentStyle === 1
        ? Theme.accentSecondary
        : accentStyle === 2
            ? Theme.moduleValue
            : Theme.frameBorder
    readonly property color surfaceColor: Theme.panel
    readonly property color elevatedColor: root.withAlpha(root.mix(
        Theme.panelHighlight,
        accentColor,
        accentStyle === 2 ? 0.025 : 0.055
    ), translucent ? 0.94 : 1)

    function mix(first, second, amount) {
        const t = Math.max(0, Math.min(1, amount));
        return Qt.rgba(
            first.r * (1 - t) + second.r * t,
            first.g * (1 - t) + second.g * t,
            first.b * (1 - t) + second.b * t,
            first.a * (1 - t) + second.a * t
        );
    }

    function withAlpha(colour, alpha) {
        return Qt.rgba(colour.r, colour.g, colour.b, alpha);
    }

    function duration(base) {
        return motionEnabled ? Math.max(1, Math.round(base * animationScale)) : 1;
    }

    function canonicalId(id) {
        const value = String(id || "");
        return value.endsWith(".desktop")
            ? value.slice(0, -8)
            : value;
    }

    function pinnedArray() {
        return pinnedIds.split("|")
            .map(id => canonicalId(id))
            .filter(id => id.length > 0);
    }

    function isPinned(id) {
        return pinnedArray().includes(canonicalId(id));
    }

    function togglePin(id) {
        const canonical = canonicalId(id);
        if (!canonical)
            return;

        const entries = pinnedArray();
        const index = entries.indexOf(canonical);
        if (index >= 0)
            entries.splice(index, 1);
        else
            entries.push(canonical);
        pinnedIds = entries.join("|");
    }

    function applyShellValues() {
        ShellConfig.uiScale = Math.max(0.9, Math.min(1.5, interfaceScale));
        ShellConfig.bar.surfaceHeight = Math.round(Math.max(44, Math.min(62, barHeight)));
        ShellConfig.bar.exclusiveZone = ShellConfig.bar.surfaceHeight;
        ShellConfig.bar.popupCornerRadius = Math.round(Math.max(6, Math.min(28, popupRadius)));
        ShellConfig.bar.mediaArtworkCornerRadius = Math.max(4,
            ShellConfig.bar.popupCornerRadius - 3);
        ShellConfig.notifications.topLeftRounding = Math.max(0,
            Math.min(42, drawerRadius));
    }

    onInterfaceScaleChanged: applyShellValues()
    onPopupRadiusChanged: applyShellValues()
    onBarHeightChanged: applyShellValues()
    onDrawerRadiusChanged: applyShellValues()

    Component.onCompleted: applyShellValues()

    FileView {
        id: settingsFile

        path: Quickshell.shellDir + "/floral-settings.json"
        watchChanges: true
        atomicWrites: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.applyShellValues()
        onLoadFailed: writeAdapter()

        JsonAdapter {
            id: saved

            property bool dockEnabled: true
            property bool dockAutoHide: false
            property bool dockMagnification: true
            property bool dockTray: true
            property bool shadows: true
            property bool ornaments: true
            property bool translucent: true
            property bool motionEnabled: true
            property real animationScale: 1
            property int iconSize: 42
            property int dockMargin: 14
            property real interfaceScale: 1.2
            property real popupRadius: 12
            property int barHeight: 50
            property real drawerRadius: 26
            property int accentStyle: 0
            property string pinnedIds: "org.mozilla.firefox|foot|org.gnome.Nautilus|app.legcord.Legcord"
            property bool idleEnabled: false
            property int idleLockTimeoutMinutes: 5
            property int idleDpmsTimeoutMinutes: 10
            property bool idleInhibitLockWhenPlaying: false
            property bool idleInhibitDpmsWhenPlaying: true
            property bool idleInhibitWhenCharging: false
            property bool idleLockBeforeSleep: true
        }
    }
}
