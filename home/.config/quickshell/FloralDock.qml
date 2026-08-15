pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    readonly property var openWindows: Hyprland.toplevels.values
    readonly property var entries: buildEntries(openWindows,
        FloralSettings.pinnedIds)

    SystemClock {
        id: dockClock
        precision: SystemClock.Minutes
    }

    function windowClass(window) {
        if (!window || !window.lastIpcObject)
            return "";
        return String(window.lastIpcObject.class
            || window.lastIpcObject.initialClass || "");
    }

    function appColour(key) {
        const palette = [
            Theme.accentPrimary,
            Theme.accentSecondary,
            Theme.accentTertiary,
            Theme.moduleLabel
        ];
        const text = String(key || "app");
        let hash = 0;
        for (let index = 0; index < text.length; ++index)
            hash = (hash * 31 + text.charCodeAt(index)) >>> 0;
        return palette[hash % palette.length];
    }

    function monogram(name) {
        const words = String(name || "app").trim().split(/\s+/)
            .filter(word => word.length > 0);
        if (words.length > 1)
            return (words[0][0] + words[1][0]).toUpperCase();
        if (!words.length)
            return "·";

        const key = words[0].toLowerCase();
        const familiar = {
            firefox: "FX",
            foot: "FT",
            files: "FL",
            nautilus: "FL",
            legcord: "LC"
        };
        return familiar[key] || words[0].slice(0, 2).toUpperCase();
    }

    function buildEntries(windows, pinnedIds) {
        const result = [];
        const keyed = {};
        const pins = pinnedIds.split("|")
            .map(id => FloralSettings.canonicalId(id))
            .filter(id => id.length > 0);

        for (const id of pins) {
            const application = DesktopEntries.byId(id);
            if (!application)
                continue;

            const item = {
                key: id,
                application: application,
                name: application.name,
                icon: application.icon,
                windows: [],
                pinned: true
            };
            keyed[id] = item;
            result.push(item);
        }

        for (const window of windows) {
            const className = windowClass(window);
            const normalized = className.toLowerCase();
            if (!normalized || normalized.includes("quickshell"))
                continue;

            const application = DesktopEntries.heuristicLookup(className);
            const key = application ? application.id : `window:${normalized}`;
            let item = keyed[key];

            if (!item) {
                item = {
                    key: key,
                    application: application,
                    name: application ? application.name : className,
                    icon: application ? application.icon : "application-x-executable",
                    windows: [],
                    pinned: application ? FloralSettings.isPinned(application.id) : false
                };
                keyed[key] = item;
                result.push(item);
            }
            item.windows.push(window);
        }

        return result;
    }

    function launch(entry) {
        if (entry.application)
            entry.application.execute();
    }

    function focus(entry) {
        if (!entry.windows.length) {
            launch(entry);
            return;
        }

        let index = entry.windows.findIndex(window => window.activated);
        index = index >= 0 && entry.windows.length > 1
            ? (index + 1) % entry.windows.length
            : 0;
        const window = entry.windows[index];
        const address = String(window.address).startsWith("0x")
            ? String(window.address)
            : `0x${window.address}`;
        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.focus({ window = "address:${address}" })`
            : `focuswindow address:${address}`);
    }

    function openLauncher() {
        FloralSettings.settingsOpen = false;
        FloralSettings.dockLauncherOpen
            = !FloralSettings.dockLauncherOpen;
    }

    function openWallpapers() {
        Quickshell.execDetached(["qs", "ipc", "call",
            "wallpaperCarousel", "toggle"]);
    }

    component DockAction: Item {
        id: action

        required property string kind
        required property string tooltip
        property bool selected: false
        property bool hovered: actionPointer.containsMouse
        signal clicked

        readonly property real baseSize: FloralSettings.iconSize
        readonly property real shownSize: hovered
            && FloralSettings.dockMagnification
            ? baseSize * 1.18
            : baseSize

        implicitWidth: shownSize + 10
        implicitHeight: FloralSettings.iconSize + 18

        Rectangle {
            anchors.centerIn: parent
            width: action.shownSize
            height: action.shownSize
            radius: width * 0.31
            color: action.selected
                ? FloralSettings.withAlpha(FloralSettings.accentColor, 0.2)
                : action.hovered
                    ? FloralSettings.elevatedColor
                    : "transparent"
            border.width: action.selected || action.hovered ? 1 : 0
            border.color: action.selected
                ? FloralSettings.accentColor
                : Theme.frameBorderFaint

            FloralGlyph {
                anchors.centerIn: parent
                width: parent.width * 0.48
                height: width
                kind: action.kind
                active: action.selected
                color: action.selected || action.hovered
                    ? FloralSettings.accentColor
                    : Theme.moduleValue
            }

            Behavior on width {
                NumberAnimation {
                    duration: FloralSettings.duration(170)
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: FloralSettings.duration(170)
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation { duration: FloralSettings.duration(130) }
            }
        }

        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.top
                bottomMargin: 9
            }
            width: actionLabel.implicitWidth + 18
            height: 29
            radius: 9
            color: FloralSettings.elevatedColor
            border.width: 1
            border.color: Theme.frameBorderFaint
            opacity: action.hovered ? 1 : 0
            scale: action.hovered ? 1 : 0.92
            visible: opacity > 0
            z: 200

            Text {
                id: actionLabel

                anchors.centerIn: parent
                text: action.tooltip
                color: Theme.moduleValue
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    styleName: ShellConfig.typography.fineStyle
                    pixelSize: 12
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: FloralSettings.duration(110) }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: FloralSettings.duration(150)
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            id: actionPointer

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.clicked()
        }
    }

    component DockDivider: Rectangle {
        implicitWidth: 1
        implicitHeight: Math.round(FloralSettings.iconSize * 0.62)
        radius: width / 2
        color: Theme.frameBorderFaint
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dockWindow

            required property ShellScreen modelData
            readonly property bool raised: !FloralSettings.dockAutoHide
                || dockHover.hovered
                || edgeHover.hovered
                || FloralSettings.dockLauncherOpen
                || FloralSettings.settingsOpen
            readonly property real inputTop: FloralSettings.dockLauncherOpen
                ? 0
                : raised ? Math.max(0, dockSurface.y - 48)
                : height - edgeTrigger.height

            screen: modelData
            visible: FloralSettings.dockEnabled
            color: "transparent"
            implicitHeight: FloralSettings.dockLauncherOpen
                ? modelData.height
                : Math.min(modelData.height,
                    FloralSettings.iconSize + 26
                        + FloralSettings.dockMargin + 56)
            exclusiveZone: FloralSettings.dockEnabled
                && !FloralSettings.dockAutoHide
                ? FloralSettings.iconSize + 26
                    + FloralSettings.dockMargin
                    + Math.round(ShellConfig.visuals.shadowOffsetY)
                : 0

            anchors {
                left: true
                right: true
                bottom: true
            }

            WlrLayershell.layer: FloralSettings.dockLauncherOpen
                ? WlrLayer.Overlay : WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Normal
            WlrLayershell.keyboardFocus: FloralSettings.dockLauncherOpen
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None

            mask: Region {
                x: FloralSettings.dockEnabled
                    && !FloralSettings.dockLauncherOpen
                    ? dockSurface.x - 14 : 0
                y: FloralSettings.dockEnabled ? dockWindow.inputTop : 0
                width: FloralSettings.dockEnabled
                    ? FloralSettings.dockLauncherOpen
                        ? dockWindow.width
                        : dockSurface.width + 28
                    : 0
                height: FloralSettings.dockEnabled
                    ? dockWindow.height - y
                    : 0
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.panel
                opacity: FloralSettings.dockLauncherOpen ? 0.42 : 0
                visible: opacity > 0
                z: 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: FloralSettings.duration(180)
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: FloralSettings.dockLauncherOpen
                z: 1
                onClicked: FloralSettings.dockLauncherOpen = false
            }

            Item {
                id: edgeTrigger

                anchors {
                    left: dockSurface.left
                    right: dockSurface.right
                    bottom: parent.bottom
                    leftMargin: -14
                    rightMargin: -14
                }
                height: Math.max(14, FloralSettings.dockMargin + 8)
                visible: FloralSettings.dockEnabled
                    && FloralSettings.dockAutoHide
                    && !FloralSettings.dockLauncherOpen
                z: 2

                HoverHandler { id: edgeHover }
            }

            FloralSurface {
                id: dockSurface

                readonly property real compactWidth: Math.min(
                    dockWindow.width - 32,
                    18 + dockClockSummary.implicitWidth
                        + 18 + dockContents.implicitWidth
                        + 24 + dockRightCluster.implicitWidth + 16)
                readonly property real compactHeight:
                    FloralSettings.iconSize + 26
                readonly property real expandedWidth: Math.min(
                    dockWindow.width - 48,
                    dockLauncher.implicitWidth
                        + ShellConfig.frame.lineThickness * 2)
                readonly property real expandedHeight: Math.min(
                    dockWindow.height - Math.max(48,
                        FloralSettings.dockMargin * 2),
                    dockLauncher.implicitHeight
                        + ShellConfig.frame.lineThickness * 2)

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: FloralSettings.dockLauncherOpen
                        ? Math.max(FloralSettings.dockMargin, 18)
                        : dockWindow.raised
                        ? FloralSettings.dockMargin
                        : -height + 8
                }
                width: FloralSettings.dockLauncherOpen
                    ? expandedWidth : compactWidth
                height: FloralSettings.dockLauncherOpen
                    ? expandedHeight : compactHeight
                radius: FloralSettings.dockLauncherOpen
                    ? Math.max(14, FloralSettings.popupRadius + 4)
                    : Math.min(24, height * 0.36)
                fillColor: FloralSettings.surfaceColor
                borderWidth: 2
                borderColor: FloralSettings.withAlpha(
                    FloralSettings.accentColor, 0.88)
                innerBorderColor: Theme.frameBorderFaint
                elevated: FloralSettings.shadows
                ornamented: FloralSettings.ornaments
                ornamentStrength: 0.11
                ornamentSize: 62
                visible: FloralSettings.dockEnabled
                clip: false
                z: 3

                MouseArea {
                    anchors.fill: parent
                    enabled: FloralSettings.dockLauncherOpen
                    z: 0
                    onClicked: mouse.accepted = true
                }

                Column {
                    id: dockClockSummary

                    anchors {
                        left: parent.left
                        leftMargin: 18
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: -1
                    opacity: FloralSettings.dockLauncherOpen ? 0 : 1
                    visible: opacity > 0
                    enabled: !FloralSettings.dockLauncherOpen
                    z: 2

                    Text {
                        text: Qt.formatDateTime(dockClock.date, "HH:mm")
                        color: Theme.moduleValue
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: 18
                            weight: Font.DemiBold
                        }
                    }

                    Text {
                        text: Qt.formatDateTime(dockClock.date,
                            "ddd, MMM d").toLowerCase()
                        color: Theme.moduleLabel
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: 10
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: FloralSettings.duration(120)
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Row {
                    id: dockContents

                    anchors {
                        left: dockClockSummary.right
                        leftMargin: 18
                        bottom: parent.bottom
                        bottomMargin: 4
                    }
                    height: dockSurface.compactHeight - 8
                    spacing: 5
                    enabled: !FloralSettings.dockLauncherOpen
                    opacity: FloralSettings.dockLauncherOpen ? 0 : 1
                    scale: FloralSettings.dockLauncherOpen ? 0.96 : 1
                    visible: opacity > 0
                    z: 2

                    DockAction {
                        anchors.verticalCenter: parent.verticalCenter
                        kind: "launcher"
                        tooltip: "applications"
                        onClicked: root.openLauncher()
                    }

                    DockDivider {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Repeater {
                        model: root.entries

                        Item {
                            id: appItem

                            required property var modelData
                            readonly property bool active: modelData.windows.some(
                                window => window.activated)
                            readonly property bool urgent: modelData.windows.some(
                                window => window.urgent)
                            readonly property bool hovered: appPointer.containsMouse
                            readonly property real baseSize: FloralSettings.iconSize
                            readonly property real shownSize: hovered
                                && FloralSettings.dockMagnification
                                ? baseSize * 1.24
                                : baseSize

                            implicitWidth: shownSize + 10
                            implicitHeight: FloralSettings.iconSize + 18
                            opacity: 1
                            scale: 1

                            Rectangle {
                                anchors.centerIn: parent
                                width: appItem.shownSize
                                height: appItem.shownSize
                                radius: width * 0.31
                                color: appItem.active
                                    ? FloralSettings.withAlpha(
                                        FloralSettings.accentColor, 0.2)
                                    : appItem.hovered
                                        ? FloralSettings.elevatedColor
                                        : "transparent"
                                border.width: appItem.active || appItem.hovered ? 1 : 0
                                border.color: appItem.urgent
                                    ? Theme.statusDanger
                                    : appItem.active
                                        ? FloralSettings.accentColor
                                        : Theme.frameBorderFaint

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: Math.max(6,
                                        Math.round(parent.width * 0.15))
                                    radius: width * 0.3
                                    color: FloralSettings.withAlpha(
                                        root.appColour(appItem.modelData.key),
                                        appItem.active ? 0.3 : 0.18)
                                    border.width: 1
                                    border.color: FloralSettings.withAlpha(
                                        root.appColour(appItem.modelData.key),
                                        0.72)

                                    FloralGlyph {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.74
                                        height: width
                                        kind: "launcher"
                                        color: root.appColour(
                                            appItem.modelData.key)
                                        opacity: 0.13
                                    }

                                    Text {
                                        id: appMonogram

                                        anchors.centerIn: parent
                                        text: root.monogram(
                                            appItem.modelData.name)
                                        color: Theme.moduleValue
                                        renderType: Text.NativeRendering
                                        font {
                                            family: ShellConfig.typography.monoFamily
                                            styleName: ShellConfig.typography.fineStyle
                                            pixelSize: Math.max(13,
                                                parent.width * (appMonogram.text.length > 1
                                                    ? 0.36 : 0.48))
                                            weight: Font.DemiBold
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: "transparent"
                                    border.width: 2
                                    border.color: Theme.statusDanger
                                    visible: appItem.urgent
                                    opacity: 0.32

                                    SequentialAnimation on opacity {
                                        running: appItem.urgent
                                            && FloralSettings.motionEnabled
                                        loops: Animation.Infinite
                                        NumberAnimation {
                                            to: 0.95
                                            duration: FloralSettings.duration(420)
                                        }
                                        NumberAnimation {
                                            to: 0.32
                                            duration: FloralSettings.duration(420)
                                        }
                                    }
                                }

                                Behavior on width {
                                    NumberAnimation {
                                        duration: FloralSettings.duration(180)
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on height {
                                    NumberAnimation {
                                        duration: FloralSettings.duration(180)
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            Row {
                                anchors {
                                    horizontalCenter: parent.horizontalCenter
                                    bottom: parent.bottom
                                    bottomMargin: 0
                                }
                                spacing: 3

                                Repeater {
                                    model: Math.min(4,
                                        appItem.modelData.windows.length)

                                    Rectangle {
                                        required property int index
                                        width: index === 0 && appItem.active ? 12 : 5
                                        height: 3
                                        radius: 2
                                        color: appItem.urgent
                                            ? Theme.statusDanger
                                            : FloralSettings.accentColor

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: FloralSettings.duration(150)
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                anchors {
                                    horizontalCenter: parent.horizontalCenter
                                    bottom: parent.top
                                    bottomMargin: 9
                                }
                                width: appLabel.implicitWidth + 20
                                height: 31
                                radius: 9
                                color: FloralSettings.elevatedColor
                                border.width: 1
                                border.color: appItem.active
                                    ? FloralSettings.accentColor
                                    : Theme.frameBorderFaint
                                opacity: appItem.hovered ? 1 : 0
                                scale: appItem.hovered ? 1 : 0.92
                                visible: opacity > 0
                                z: 200

                                Text {
                                    id: appLabel

                                    anchors.centerIn: parent
                                    text: appItem.modelData.name
                                    color: Theme.moduleValue
                                    renderType: Text.NativeRendering
                                    font {
                                        family: ShellConfig.typography.monoFamily
                                        styleName: ShellConfig.typography.fineStyle
                                        pixelSize: 12
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: FloralSettings.duration(110)
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: FloralSettings.duration(150)
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            MouseArea {
                                id: appPointer

                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton
                                    | Qt.MiddleButton
                                    | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: event => {
                                    if (event.button === Qt.RightButton) {
                                        if (appItem.modelData.application)
                                            FloralSettings.togglePin(
                                                appItem.modelData.application.id);
                                    } else if (event.button === Qt.MiddleButton) {
                                        root.launch(appItem.modelData);
                                    } else {
                                        root.focus(appItem.modelData);
                                    }
                                }
                            }
                        }
                    }

                    DockDivider {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    DockAction {
                        anchors.verticalCenter: parent.verticalCenter
                        kind: "wallpaper"
                        tooltip: "wallpapers"
                        onClicked: root.openWallpapers()
                    }

                    DockAction {
                        anchors.verticalCenter: parent.verticalCenter
                        kind: "settings"
                        tooltip: "settings"
                        selected: FloralSettings.settingsOpen
                        onClicked: FloralSettings.settingsOpen
                            = !FloralSettings.settingsOpen
                    }
                }

                Row {
                    id: dockRightCluster

                    anchors {
                        right: parent.right
                        rightMargin: 16
                        bottom: parent.bottom
                        bottomMargin: 4
                    }
                    height: dockSurface.compactHeight - 8
                    spacing: 5
                    enabled: !FloralSettings.dockLauncherOpen
                    opacity: FloralSettings.dockLauncherOpen ? 0 : 1
                    scale: FloralSettings.dockLauncherOpen ? 0.96 : 1
                    visible: opacity > 0
                    z: 2

                    DockDivider {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: FloralSettings.dockTray
                            && SystemTray.items.values.length > 0
                    }

                    Repeater {
                        model: FloralSettings.dockTray
                            ? SystemTray.items.values
                            : []

                        Item {
                            id: trayItem

                            required property var modelData
                            readonly property bool hovered: trayPointer.containsMouse
                            implicitWidth: FloralSettings.iconSize * 0.72 + 8
                            implicitHeight: FloralSettings.iconSize + 18

                            Rectangle {
                                anchors.centerIn: parent
                                width: FloralSettings.iconSize * 0.72
                                height: width
                                radius: width * 0.32
                                color: trayItem.hovered
                                    ? FloralSettings.elevatedColor
                                    : "transparent"
                                border.width: trayItem.hovered ? 1 : 0
                                border.color: Theme.frameBorderFaint

                                IconImage {
                                    anchors.fill: parent
                                    anchors.margins: 7
                                    source: trayItem.modelData.icon
                                }
                            }

                            Rectangle {
                                anchors {
                                    horizontalCenter: parent.horizontalCenter
                                    bottom: parent.top
                                    bottomMargin: 9
                                }
                                width: trayLabel.implicitWidth + 18
                                height: 29
                                radius: 9
                                color: FloralSettings.elevatedColor
                                border.width: 1
                                border.color: Theme.frameBorderFaint
                                opacity: trayItem.hovered ? 1 : 0
                                visible: opacity > 0
                                z: 200

                                Text {
                                    id: trayLabel

                                    anchors.centerIn: parent
                                    text: trayItem.modelData.tooltipTitle
                                        || trayItem.modelData.title
                                    color: Theme.moduleValue
                                    renderType: Text.NativeRendering
                                    font {
                                        family: ShellConfig.typography.monoFamily
                                        styleName: ShellConfig.typography.fineStyle
                                        pixelSize: 12
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: FloralSettings.duration(110)
                                    }
                                }
                            }

                            MouseArea {
                                id: trayPointer

                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: event => {
                                    if (event.button === Qt.RightButton)
                                        trayItem.modelData.secondaryActivate();
                                    else
                                        trayItem.modelData.activate();
                                }
                                onWheel: event => trayItem.modelData.scroll(
                                    event.angleDelta.y, false)
                            }
                        }
                    }

                    BatteryModule {
                        id: dockBattery

                        anchors.verticalCenter: parent.verticalCenter
                    }
                }


                Item {
                    id: launcherViewport

                    anchors.fill: parent
                    anchors.margins: ShellConfig.frame.lineThickness
                    clip: true
                    z: 2
                    layer.enabled: FloralSettings.dockLauncherOpen
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: launcherClipMask
                        maskSpreadAtMin: 1
                        maskThresholdMin: 0.5
                        autoPaddingEnabled: false
                    }

                    FloralDockLauncher {
                        id: dockLauncher

                        anchors.fill: parent
                        screen: dockWindow.modelData
                        panels: dockPanelContract
                        maxHeight: dockWindow.height
                            - Math.max(48, FloralSettings.dockMargin * 2)
                        enabled: FloralSettings.dockLauncherOpen
                        opacity: FloralSettings.dockLauncherOpen ? 1 : 0
                        scale: FloralSettings.dockLauncherOpen ? 1 : 0.97
                        visible: opacity > 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: FloralSettings.duration(160)
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: FloralSettings.duration(210)
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Rectangle {
                    id: launcherClipMask

                    anchors.fill: launcherViewport
                    radius: Math.max(0, dockSurface.radius
                        - ShellConfig.frame.lineThickness)
                    color: "white"
                    visible: false
                    layer.enabled: true
                }

                HoverHandler { id: dockHover }

                Behavior on height {
                    NumberAnimation {
                        duration: FloralSettings.duration(260)
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on radius {
                    NumberAnimation {
                        duration: FloralSettings.duration(210)
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on anchors.bottomMargin {
                    NumberAnimation {
                        duration: FloralSettings.duration(230)
                        easing.type: Easing.InOutCubic
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: FloralSettings.duration(260)
                        easing.type: Easing.OutCubic
                    }
                }
            }

            QtObject {
                id: dockPanelContract

                readonly property QtObject dashboard: QtObject {
                    property real nonAnimHeight: 0
                }

                readonly property QtObject bar: QtObject {
                    property real implicitWidth: 0
                }

                readonly property QtObject popouts: QtObject {
                    property bool hasCurrent: false
                    property real currentCenter: 0
                    property real nonAnimHeight: 0
                    property real nonAnimWidth: 0
                }

                readonly property QtObject utilities: QtObject {
                    property real implicitWidth: 0
                }
            }
        }
    }
}
