pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs
import qs.components

Item {
    id: root

    required property ScreenState screenState
    required property bool sidebarVisible
    readonly property real nonAnimWidth: content.implicitWidth

    readonly property bool shouldBeActive: screenState.session && Config.session.enabled
    property real offsetScale: shouldBeActive ? 0 : 1
    property real sidebarOffset: sidebarVisible ? 14 : 0

    visible: offsetScale < 1
    anchors.rightMargin: (-implicitWidth - 5 - sidebarOffset) * offsetScale
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight || 510 * ShellConfig.uiScale // Hard coded fallback for first open
    opacity: 1 - offsetScale * 0.82
    scale: 1 - offsetScale * 0.018
    transformOrigin: Item.Right

    Behavior on offsetScale {
        Anim {
            type: Anim.Emphasized
        }
    }

    Loader {
        id: content

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
        }
    }
}
