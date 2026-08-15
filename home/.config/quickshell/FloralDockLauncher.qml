pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import qs.components
import qs.modules.launcher as Launcher

Item {
    id: root

    required property ShellScreen screen
    required property var panels
    required property real maxHeight

    readonly property bool active: FloralSettings.dockLauncherOpen

    implicitWidth: launcherContent.implicitWidth
    implicitHeight: launcherContent.implicitHeight
    clip: true

    component LauncherCorner: Item {
        id: corner

        required property rect sourceRect

        Image {
            id: artwork

            anchors.fill: parent
            source: `file://${Quickshell.env("HOME")}/.config/hypr/assets/imgborders-floral-mask.png`
            sourceClipRect: corner.sourceRect
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            visible: false
        }

        MultiEffect {
            anchors.fill: artwork
            source: artwork
            colorization: 1
            colorizationColor: Theme.frameBorder
            opacity: 1
        }
    }

    ScreenState {
        id: dockScreenState

        modelData: root.screen

        onLauncherChanged: {
            if (FloralSettings.dockLauncherOpen !== launcher)
                FloralSettings.dockLauncherOpen = launcher;
        }
    }

    Launcher.Content {
        id: launcherContent

        width: root.width
        height: root.height
        screenState: dockScreenState
        panels: root.panels
        maxHeight: root.maxHeight
        animateGeometry: false
        enabled: root.active
        z: 1
    }

    LauncherCorner {
        anchors {
            left: parent.left
            top: parent.top
            margins: 5
        }
        width: Math.min(104, root.width * 0.19)
        height: width
        sourceRect: Qt.rect(0, 0, 626, 626)
        visible: root.active
        z: 2
    }

    LauncherCorner {
        anchors {
            right: parent.right
            top: parent.top
            margins: 5
        }
        width: Math.min(104, root.width * 0.19)
        height: width
        sourceRect: Qt.rect(628, 0, 626, 626)
        visible: root.active
        z: 2
    }

    Connections {
        target: FloralSettings

        function onDockLauncherOpenChanged(): void {
            if (dockScreenState.launcher !== FloralSettings.dockLauncherOpen)
                dockScreenState.launcher = FloralSettings.dockLauncherOpen;
        }
    }

    Component.onCompleted:
        dockScreenState.launcher = FloralSettings.dockLauncherOpen
}
